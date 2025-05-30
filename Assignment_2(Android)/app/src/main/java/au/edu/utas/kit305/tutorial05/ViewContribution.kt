package au.edu.utas.kit305.tutorial05


import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import au.edu.utas.kit305.tutorial05.databinding.ActivityViewContributionBinding
import au.edu.utas.kit305.tutorial05.databinding.ItemPlayerStatsBinding
import com.github.mikephil.charting.data.PieData
import com.github.mikephil.charting.data.PieDataSet
import com.github.mikephil.charting.data.PieEntry
import com.github.mikephil.charting.formatter.PercentFormatter
import com.github.mikephil.charting.utils.ColorTemplate
import com.google.firebase.firestore.FirebaseFirestore
import kotlin.math.roundToInt

class ViewContribution : AppCompatActivity() {
    private lateinit var ui: ActivityViewContributionBinding
    private lateinit var db: FirebaseFirestore
    private val playerStatsList = mutableListOf<PlayerStats>()
    private lateinit var adapter: PlayerStatsAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ui = ActivityViewContributionBinding.inflate(layoutInflater)
        setContentView(ui.root)

        // Set up  RecyclerView
        ui.recyclerContribution.layoutManager = LinearLayoutManager(this)
        adapter = PlayerStatsAdapter(playerStatsList)
        ui.recyclerContribution.adapter = adapter
        adapter.notifyDataSetChanged()

        db = FirebaseFirestore.getInstance()

        val matchID = intent.getStringExtra("Match_ID")
        val teamName = intent.getStringExtra("TEAM_NAME")

        if (!matchID.isNullOrEmpty()) {
            Log.e("ViewContribution", "check: Match_ID is $matchID TeamName is $teamName!")
            fetchPlayerContributions(matchID, teamName ?: "")
        } else {
            Log.e("ViewContribution", "Error: Match_ID is null!")
            Toast.makeText(this, "Error: Match ID not found", Toast.LENGTH_SHORT).show()
        }
        ui.Close.setOnClickListener {
            finish()
        }

    }

    private fun fetchPlayerContributions(matchID: String, teamName: String) {
        db.collection("matches").document(matchID).collection("history_actions")
            .whereEqualTo("team", teamName)
            .get()
            .addOnSuccessListener { result ->
                Log.d("Firebase", "Fetched ${result.size()} documents")
                val playerStatsMap = mutableMapOf<String, PlayerStats>()

                for (document in result) {
                    val playerName = document.getString("player") ?: continue
                    val actionType = document.getString("actionType") ?: continue

                    val playerStats = playerStatsMap.getOrPut(playerName) {
                        PlayerStats(playerName, 0, 0, 0, 0, 0, 0, 0)
                    }

                    when (actionType) {
                        "Kick Goal Scored (6 Points)" -> playerStats.totalKickGoals++
                        "Kick Behind Scored (1 Point)" -> playerStats.totalKickBehinds++
                        "Kick No Score(0 Points)" -> playerStats.totalKickNoScore++
                        "Mark (catching the ball)" -> playerStats.totalMarks++
                        "Tackle" -> playerStats.totalTackles++
                        "Handball Behind Score (1 Point)" -> playerStats.totalHandballBehinds++
                    }

                    playerStats.totalScore = (playerStats.totalKickGoals * 6) +
                            playerStats.totalKickBehinds +
                            playerStats.totalHandballBehinds
                }

                playerStatsList.clear()
                playerStatsList.addAll(playerStatsMap.values)
                adapter.notifyDataSetChanged()
                fun updatePieChart() {
                    val entries = ArrayList<PieEntry>()
                    val totalTeamScore = playerStatsList.sumOf { it.totalScore } // Calculate team's totalScore

                    if (totalTeamScore > 0) { // Avoid division by zero
                        for (playerStats in playerStatsList) {
                            val percentage = (playerStats.totalScore.toFloat() / totalTeamScore) * 100
                            entries.add(PieEntry(percentage, playerStats.playerName))
                        }
                    }
                    //Ask GTP how to insert the data to the pie chart and generate the pie chart in the in interface
                    val dataSet = PieDataSet(entries, "Player Contribution").apply {
                        colors = ColorTemplate.COLORFUL_COLORS.toList()
                        valueTextSize = 14f
                        valueFormatter = PercentFormatter()
                    }

                    val pieData = PieData(dataSet)
                    ui.pieChart.apply {
                        data = pieData
                        description.isEnabled = false
                        isDrawHoleEnabled = true
                        setUsePercentValues(true)
                        invalidate() // Update the chart
                    }
                }
                // Update PieChart after loading all player data
                updatePieChart()
                Log.d("Firebase", "Updated playerStatsList with ${playerStatsList.size} players")
            }
            .addOnFailureListener { e ->
                Log.e("Firebase", "Error fetching player contributions", e)
            }
    }


    inner class PlayerStatsAdapter(private val playerStatsList: List<PlayerStats>) :
        RecyclerView.Adapter<PlayerStatsAdapter.PlayerStatsViewHolder>() {

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): PlayerStatsViewHolder {
            val binding = ItemPlayerStatsBinding.inflate(LayoutInflater.from(parent.context), parent, false)
            return PlayerStatsViewHolder(binding)
        }

        override fun onBindViewHolder(holder: PlayerStatsViewHolder, position: Int) {
            holder.bind(playerStatsList[position])
        }

        override fun getItemCount(): Int = playerStatsList.size

        inner class PlayerStatsViewHolder(private val binding: ItemPlayerStatsBinding) :
            RecyclerView.ViewHolder(binding.root) {

            fun bind(playerStats: PlayerStats) {
                binding.playerName.apply {
                    text = playerStats.playerName
                    setTypeface(null, android.graphics.Typeface.BOLD) // set up bold typeface
                }
                binding.kicks.text = "Kicks: ${playerStats.totalKickGoals + playerStats.totalKickBehinds+playerStats.totalKickNoScore}"
                binding.handballs.text = "Handballs: ${playerStats.totalHandballBehinds}"
                binding.tackles.text = "Tackles: ${playerStats.totalTackles}"
                binding.marks.text = "Marks: ${playerStats.totalMarks}"
                binding.goals.text = "Goals: ${playerStats.totalKickGoals}"
                binding.behinds.text = "Behinds: ${playerStats.totalKickBehinds + playerStats.totalHandballBehinds}"
                binding.totalScore.text = "Total Score: ${playerStats.totalScore}"
                binding.percentageContribution.text="Persentage: ${((playerStats.totalScore.toFloat() / playerStatsList.sumOf { it.totalScore }) * 100).roundToInt()}%"

            }


        }
    }
}

