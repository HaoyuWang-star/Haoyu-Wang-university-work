package au.edu.utas.kit305.tutorial05

import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Spinner
import androidx.appcompat.app.AppCompatActivity
import au.edu.utas.kit305.tutorial05.databinding.ActivityPlayerCompareBinding
import com.github.mikephil.charting.charts.BarChart
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.data.BarData
import com.github.mikephil.charting.data.BarDataSet
import com.github.mikephil.charting.data.BarEntry
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter
import com.google.firebase.firestore.FirebaseFirestore

class PlayerCompareActivity : AppCompatActivity() {

    private lateinit var ui: ActivityPlayerCompareBinding
    private lateinit var db: FirebaseFirestore
    private lateinit var teamList: List<String>
    private lateinit var playerList: MutableList<String>
    private lateinit var leftTeamSpinner: Spinner
    private lateinit var leftPlayerSpinner: Spinner
    private lateinit var rightTeamSpinner: Spinner
    private lateinit var rightPlayerSpinner: Spinner
    private lateinit var barChart: BarChart
    private lateinit var matchID: String
    private lateinit var team1Name: String
    private lateinit var team2Name: String
    private var leftPlayerStats: PlayerStats? = null
    private var rightPlayerStats: PlayerStats? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ui = ActivityPlayerCompareBinding.inflate(layoutInflater)
        setContentView(ui.root)

        db = FirebaseFirestore.getInstance()

        leftTeamSpinner = findViewById(R.id.spinnerLeftTeam)
        leftPlayerSpinner = findViewById(R.id.spinnerLeftPlayer)
        rightTeamSpinner = findViewById(R.id.spinnerRightTeam)
        rightPlayerSpinner = findViewById(R.id.spinnerRightPlayer)
        barChart = findViewById(R.id.barChart)

        // Get passed data from the Intent
        matchID = intent.getStringExtra("Match_ID") ?: ""
        team1Name = intent.getStringExtra("TEAM1_NAME") ?: ""
        team2Name = intent.getStringExtra("TEAM2_NAME") ?: ""

        // Set teams to Spinner
        teamList = listOf(team1Name, team2Name)
        val teamAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, teamList)
        teamAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        leftTeamSpinner.adapter = teamAdapter
        rightTeamSpinner.adapter = teamAdapter

        leftTeamSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>, view: View?, position: Int, id: Long) {
                fetchPlayersForTeam(leftTeamSpinner.selectedItem.toString(), true)
            }

            override fun onNothingSelected(parent: AdapterView<*>) {}
        }

        rightTeamSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>, view: View?, position: Int, id: Long) {
                fetchPlayersForTeam(rightTeamSpinner.selectedItem.toString(), false)
            }

            override fun onNothingSelected(parent: AdapterView<*>) {}
        }

        leftPlayerSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>, view: View?, position: Int, id: Long) {
                // Avoid calling fetchPlayerStats when no item is selected
                val selectedPlayer = leftPlayerSpinner.selectedItem.toString()
                if (selectedPlayer.isNotEmpty()) {
                    fetchPlayerStats(leftTeamSpinner.selectedItem.toString(), selectedPlayer, true)
                }
            }

            override fun onNothingSelected(parent: AdapterView<*>) {
                // Handle case when no item is selected
            }
        }

        Log.d("PlayerCompare", "Selected Player: ${leftPlayerSpinner.selectedItem}")
        rightPlayerSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>, view: View?, position: Int, id: Long) {
                // Avoid calling fetchPlayerStats when no item is selected
                val selectedPlayer = rightPlayerSpinner.selectedItem.toString()
                if (selectedPlayer.isNotEmpty() && leftPlayerSpinner.selectedItem != null) {
                    fetchPlayerStats(rightTeamSpinner.selectedItem.toString(), selectedPlayer, false)
                }
            }

            override fun onNothingSelected(parent: AdapterView<*>) {
                // Handle case when no item is selected
            }
        }
        Log.d("PlayerCompare", "Selected Player: ${rightPlayerSpinner.selectedItem}")
        leftPlayerSpinner.setSelection(0)
        rightPlayerSpinner.setSelection(0)

        // Set OnClickListener for the Compare button

        ui.btnClose.setOnClickListener {
        finish()
        }
    }

    private fun fetchPlayersForTeam(teamName: String, isLeft: Boolean) {
        db.collection("players")
            .whereEqualTo("team_belong", teamName)
            .get()
            .addOnSuccessListener { result ->
                playerList = result.map { it.getString("name") ?: "" }.toMutableList()
                Log.d("PlayerCompare", "Fetched players for $teamName: $playerList")
                val playerAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, playerList)
                playerAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)

                if (isLeft) {
                    leftPlayerSpinner.adapter = playerAdapter
                } else {
                    rightPlayerSpinner.adapter = playerAdapter
                }
            }
            .addOnFailureListener { e ->
                Log.e("PlayerCompare", "Error fetching players for team $teamName", e)
            }
    }

    private fun fetchPlayerStats(teamName: String, playerName: String, isLeft: Boolean) {
        // Fetch player actions from the history_actions subcollection for the selected match
        db.collection("matches")
            .document("$matchID")  // Use Match_ID to filter the match
            .collection("history_actions")
            .whereEqualTo("team", teamName)  // Filter actions by team
            .get()
            .addOnSuccessListener { result ->
                var totalKickGoals = 0
                var totalKickBehinds = 0
                var totalHandballBehinds = 0
                var totalMarks = 0
                var totalTackles = 0

                for (document in result) {
                    val actionPlayer = document.getString("player") ?: continue
                    if (actionPlayer != playerName) continue

                    val actionType = document.getString("actionType") ?: continue

                    when (actionType) {
                        "Kick Goal Scored (6 Points)" -> totalKickGoals++
                        "Kick Behind Scored (1 Point)" -> totalKickBehinds++
                        "Kick No Score (0 Points)" -> totalKickGoals++
                        "Handball Behind Score (1 Point)" -> totalHandballBehinds++
                        // other actions...
                    }
                }


                // Calculate total score
                val totalScore = (totalKickGoals * 6) + (totalKickBehinds * 1) + (totalHandballBehinds * 1)

                val playerStats = PlayerStats(
                    playerName, totalKickGoals, totalKickBehinds, 0, totalHandballBehinds, totalMarks, totalTackles, totalScore
                )

                // Update the Bar chart with the player stats
                if (isLeft) {
                    leftPlayerStats = playerStats
                } else {
                    rightPlayerStats = playerStats
                }

                if (leftPlayerStats != null && rightPlayerStats != null) {
                    val left = leftPlayerStats!!
                    val right = rightPlayerStats!!
                    updateBarChart(left, right)
                }

            }
            .addOnFailureListener { e ->
                Log.e("PlayerCompare", "Error fetching player stats", e)
            }
    }

    private fun updateBarChart(leftStats: PlayerStats, rightStats: PlayerStats) {
        val totalKick = leftStats.totalKickGoals + rightStats.totalKickGoals
        val totalHandball = leftStats.totalHandballBehinds + rightStats.totalHandballBehinds
        val totalScore = leftStats.totalScore + rightStats.totalScore

        val leftKickPct = if (totalKick > 0) leftStats.totalKickGoals.toFloat() / totalKick * 100 else 0f
        val rightKickPct = if (totalKick > 0) rightStats.totalKickGoals.toFloat() / totalKick * 100 else 0f

        val leftHandballPct = if (totalHandball > 0) leftStats.totalHandballBehinds.toFloat() / totalHandball * 100 else 0f
        val rightHandballPct = if (totalHandball > 0) rightStats.totalHandballBehinds.toFloat() / totalHandball * 100 else 0f

        val leftScorePct = if (totalScore > 0) leftStats.totalScore.toFloat() / totalScore * 100 else 0f
        val rightScorePct = if (totalScore > 0) rightStats.totalScore.toFloat() / totalScore * 100 else 0f

        val leftEntries = listOf(
            BarEntry(0f, leftKickPct),
            BarEntry(1f, leftHandballPct),
            BarEntry(2f, leftScorePct)
        )

        val rightEntries = listOf(
            BarEntry(0f, rightKickPct),
            BarEntry(1f, rightHandballPct),
            BarEntry(2f, rightScorePct)
        )

        val leftDataSet = BarDataSet(leftEntries, leftStats.playerName).apply {
            color = Color.rgb(104, 241, 175)
            valueTextSize = 12f
        }

        val rightDataSet = BarDataSet(rightEntries, rightStats.playerName).apply {
            color = Color.rgb(164, 228, 251)
            valueTextSize = 12f
        }

        val barData = BarData(leftDataSet, rightDataSet)

        val groupSpace = 0.2f
        val barSpace = 0.05f
        val barWidth = 0.35f

        barData.barWidth = barWidth

        barData.barWidth = barWidth

        barChart.data = barData
        barChart.xAxis.apply {
            valueFormatter = IndexAxisValueFormatter(listOf("Kick", "Handball", "TotalScore"))
            granularity = 1f  // Use 1 to ensure that labels do not overlap
            isGranularityEnabled = true
            position = XAxis.XAxisPosition.BOTTOM
            setAvoidFirstLastClipping(true)
            setDrawGridLines(false)
            textSize = 12f

            // Adjust spaceMin to avoid overlapping labels
            spaceMin = 0.1f  // Small increase in left margin to avoid overlap

            //Try turning off centreAxisLabels to avoid excessive label offsets!
            setCenterAxisLabels(false)
        }


        barChart.axisLeft.apply {
            axisMinimum = 0f
            textSize = 12f
        }

        barChart.axisRight.isEnabled = false
        barChart.description.isEnabled = false
        barChart.legend.isEnabled = true
        barChart.setFitBars(true)

        // Zoom & Move
        barChart.setScaleMinima(0.9f, 1f)
        barChart.moveViewToX(0f)

        // Setting up Bar Chart Groups
        barChart.groupBars(-0.3f, groupSpace, barSpace)
        barChart.invalidate()
    }


}

