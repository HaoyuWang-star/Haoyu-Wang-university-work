package au.edu.utas.kit305.tutorial05

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import au.edu.utas.kit305.tutorial05.databinding.ActivityViewWormBinding
import com.github.mikephil.charting.charts.LineChart
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.data.LineData
import com.github.mikephil.charting.data.LineDataSet
import com.github.mikephil.charting.highlight.Highlight
import com.github.mikephil.charting.listener.OnChartValueSelectedListener
import com.google.firebase.firestore.FirebaseFirestore



class ViewWorm : AppCompatActivity() {
    private lateinit var team1Name: String
    private lateinit var team2Name: String
    private lateinit var binding: ActivityViewWormBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityViewWormBinding.inflate(layoutInflater)
        setContentView(binding.root)

        team1Name = intent.getStringExtra("TEAM1_NAME") ?: ""
        team2Name = intent.getStringExtra("TEAM2_NAME") ?: ""
        val matchId = intent.getStringExtra("Match_ID") ?: ""
        setupWormGraph(team1Name, team2Name, matchId)

        binding.btnClose.setOnClickListener {
            finish()
        }
    }
    //Asking GPT how to generate the worm graph base on the history record data,regulating and revising codes by myself
    private fun setupWormGraph(team1: String, team2: String, matchId: String) {
        val db = FirebaseFirestore.getInstance()
        val actionsRef = db.collection("matches").document(matchId).collection("history_actions")

        actionsRef.orderBy("timestamp").get().addOnSuccessListener { result ->
            data class ScoreSnapshot(val team1Score: Int, val team2Score: Int)
            val entries = mutableListOf<Entry>()
            var team1Score = 0
            var team2Score = 0
            var index = 0f

            for (document in result) {
                val team = document.getString("team")
                val actionType = document.getString("actionType")
                if (team == team1) {
                    if (actionType!!.contains("6 Points")) team1Score += 6
                    else if (actionType.contains("1 Point")) team1Score += 1
                } else if (team == team2) {
                    if (actionType!!.contains("6 Points")) team2Score += 6
                    else if (actionType.contains("1 Point")) team2Score += 1
                }

                val margin = (team1Score - team2Score).toFloat()

                val entry = Entry(index, margin)
                entry.data = ScoreSnapshot(team1Score, team2Score)

                entries.add(entry)
                index += 1
            }

            val lineDataSet = LineDataSet(entries, "Margin Over Time").apply {
                color = Color.BLUE
                lineWidth = 2f
                setDrawCircles(true)
                setDrawValues(false)
                setDrawHighlightIndicators(true)
            }

            val lineData = LineData(lineDataSet)
            val chart = findViewById<LineChart>(R.id.wormChart)
            chart.data = lineData
            chart.description.text = "Score Margin: $team1 vs $team2"
            chart.description.textSize = 16f // set the text size for description
            chart.invalidate()

            // Set click interaction
            chart.setOnChartValueSelectedListener(object : OnChartValueSelectedListener {
                override fun onValueSelected(e: Entry?, h: Highlight?) {
                    if (e != null && e.data is ScoreSnapshot) {
                        val snapshot = e.data as ScoreSnapshot
                        val t1Score = snapshot.team1Score
                        val t2Score = snapshot.team2Score
                        val margin = t1Score - t2Score // calculate margin
                        val time = e.x // time based on x-axis value (can be seconds or any unit)

                        // Format time (optional, depending on your requirements)
                        val formattedTime = formatTime(time)

                        // Show the score and margin at that point in time in a Toast
                        Toast.makeText(
                            this@ViewWorm,
                            "Time: $formattedTime" + " Margin: $margin\n" + "$team1: $t1Score | $team2: $t2Score",
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                }

                override fun onNothingSelected() {
                    // Do nothing if no value is selected
                }
            })
        }
    }

    // Helper function to format time
    private fun formatTime(time: Float): String {
        // Assuming time is in seconds, adjust as per your requirements
        val minutes = (time / 60).toInt()
        val seconds = (time % 60).toInt()
        return String.format("%02d:%02d", minutes, seconds)
    }
}
