package au.edu.utas.kit305.tutorial05

import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.firebase.Firebase
import com.google.firebase.firestore.firestore

class MatchView : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_match_view)
        val team1Name = intent.getStringExtra("TEAM1_NAME") ?: ""
        val team2Name = intent.getStringExtra("TEAM2_NAME") ?: ""

        val MATCH_ID = intent.getStringExtra("Match_ID") // chnage to "Match_ID"，align with putExtra
        Log.d("MatchView", "Received MATCH_ID: $MATCH_ID")
        if (MATCH_ID != null) {
            fetchTeamStats(MATCH_ID) // check database
        } else {
            Log.e("MatchView", "Error: MATCH_ID is null!")
            Toast.makeText(this, "Error: Match ID not found", Toast.LENGTH_SHORT).show()
        }

        findViewById<TextView>(R.id.teamtitle).text = "$team1Name VS $team2Name match quarters:"
        findViewById<Button>(R.id.button_close).setOnClickListener {
            finish()
        }



    }
    private fun fetchTeamStats(MATCH_ID: String) {
        val db = Firebase.firestore
        db.collection("matches").document(MATCH_ID).get()
            .addOnSuccessListener { matchDoc ->
                val team1 = matchDoc.getString("team1")
                val team2 = matchDoc.getString("team2")

                if (team1 == null || team2 == null) {
                    Toast.makeText(this, "Match teams not properly defined.", Toast.LENGTH_SHORT).show()
                    return@addOnSuccessListener
                }

                db.collection("matches").document(MATCH_ID).collection("history_actions")
                    .get()
                    .addOnSuccessListener { documents ->
                        if (!documents.isEmpty) {
                            val scoreMap = mutableMapOf<String, MutableMap<String, ScoreData>>() // team -> quarter -> scores

                            for (document in documents) {
                                val team = document.getString("team") ?: continue
                                val quarter = document.getString("quarter") ?: continue
                                val actionType = document.getString("actionType") ?: continue

                                // Initialize score entry if missing
                                if (scoreMap[team] == null) {
                                    scoreMap[team] = mutableMapOf()
                                }
                                if (scoreMap[team]!![quarter] == null) {
                                    scoreMap[team]!![quarter] = ScoreData()
                                }

                                // Count action types
                                when (actionType) {
                                    "Kick Goal Scored (6 Points)" -> scoreMap[team]!![quarter]!!.kickGoals++
                                    "Kick Behind Scored (1 Point)" -> scoreMap[team]!![quarter]!!.kickBehinds++
                                    "Handball Behind Score (1 Point)" -> scoreMap[team]!![quarter]!!.handballBehinds++
                                }
                            }

                            // Display scores for each quarter in the order team1 VS team2
                            for (q in 1..4) {
                                val quarterKey = q.toString()

                                val team1Data = scoreMap[team1]?.get(quarterKey) ?: ScoreData()
                                val team2Data = scoreMap[team2]?.get(quarterKey) ?: ScoreData()

                                val team1Score = (team1Data.kickGoals * 6) + (team1Data.kickBehinds + team1Data.handballBehinds)
                                val team2Score = (team2Data.kickGoals * 6) + (team2Data.kickBehinds + team2Data.handballBehinds)

                                val scoreText = "${team1Data.kickGoals}.${team1Data.kickBehinds + team1Data.handballBehinds} ($team1Score)  VS  " +
                                        "${team2Data.kickGoals}.${team2Data.kickBehinds + team2Data.handballBehinds} ($team2Score)"

                                findViewById<TextView>(
                                    when (q) {
                                        1 -> R.id.txtQ1
                                        2 -> R.id.txtQ2
                                        3 -> R.id.txtQ3
                                        4 -> R.id.txtQ4
                                        else -> return@addOnSuccessListener
                                    }
                                ).text = scoreText
                            }
                        } else {
                            Toast.makeText(this, "No actions found for match $MATCH_ID", Toast.LENGTH_SHORT).show()
                        }
                    }
                    .addOnFailureListener { e ->
                        Toast.makeText(this, "Failed to fetch match history: ${e.message}", Toast.LENGTH_SHORT).show()
                    }
            }
            .addOnFailureListener { e ->
                Toast.makeText(this, "Failed to fetch match data: ${e.message}", Toast.LENGTH_SHORT).show()
            }
    }

}