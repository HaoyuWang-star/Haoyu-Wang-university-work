package au.edu.utas.kit305.tutorial05

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.Tasks
import com.google.firebase.Firebase
import com.google.firebase.firestore.QuerySnapshot
import com.google.firebase.firestore.firestore

class TeamRecord : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_team_record)


        val teamName = intent.getStringExtra("TEAM_NAME") ?: "Unknown" // 获取 team 名字
        fetchTeamStats(teamName) // query database

        val MATCH_ID = intent.getStringExtra("Match_ID") // change to "Match_ID"，align with putExtra
        findViewById<Button>(R.id.button_players).setOnClickListener {
            val intent = Intent(this, ViewPlayers::class.java)
            intent.putExtra("TEAM_NAME", teamName)
            intent.putExtra("MATCH_ID", MATCH_ID)
            startActivity(intent)
        }
        // Navigate to MatchCreate Activity when "Create Match" button is clicked
        findViewById<Button>(R.id.button_back).setOnClickListener {
            finish()
        }



    }
    private fun fetchTeamStats(teamName: String) {
        val db = Firebase.firestore

        db.collection("matches")
            .get()
            .addOnSuccessListener { matchDocuments ->
                if (!matchDocuments.isEmpty) {
                    var totalDisposals = 0
                    var totalMarks = 0
                    var totalTackles = 0
                    var totalKickGoals = 0
                    var totalKickBehinds = 0
                    var totalHandballBehinds = 0

                    val matchFetchTasks = mutableListOf<Task<QuerySnapshot>>()

                    for (matchDocument in matchDocuments) {
                        val matchId = matchDocument.id
                        val task = db.collection("matches").document(matchId).collection("history_actions")
                            .whereEqualTo("team", teamName)
                            .get()
                        matchFetchTasks.add(task)
                    }

                    Tasks.whenAllSuccess<QuerySnapshot>(matchFetchTasks)
                        .addOnSuccessListener { results ->
                            for (documents in results) {
                                for (document in documents) {
                                    val actionType = document.getString("actionType") ?: continue

                                    when (actionType) {
                                        "Kick Goal Scored (6 Points)" -> totalKickGoals++
                                        "Kick Behind Scored (1 Point)" -> totalKickBehinds++
                                        "Handball Behind Score (1 Point)" -> totalHandballBehinds++
                                        "Mark (catching the ball)" -> totalMarks++
                                        "Tackle" -> totalTackles++
                                    }
                                    // Every kick or handball counts as a disposal
                                    if (actionType.contains("Kick") || actionType.contains("Handball")) {
                                        totalDisposals++
                                    }
                                }
                            }

                            val totalScore = (totalKickGoals * 6) + (totalKickBehinds + totalHandballBehinds)
                            val totalBehind = totalKickBehinds + totalHandballBehinds
                            // Update UI
                            findViewById<TextView>(R.id.teamtitle).text = "$teamName Stats to be shown:"
                            findViewById<TextView>(R.id.teamDis).text = "Disposals (Kicks + Handballs): $totalDisposals"
                            findViewById<TextView>(R.id.teamMar).text = "Marks: $totalMarks"
                            findViewById<TextView>(R.id.teamTac).text = "Tackles: $totalTackles"
                            findViewById<TextView>(R.id.teamTotal).text = "Score \nGoals . Behinds (Total): $totalKickGoals.$totalBehind($totalScore)"
                        }
                        .addOnFailureListener { e ->
                            Toast.makeText(this, "Failed to fetch actions: ${e.message}", Toast.LENGTH_SHORT).show()
                        }
                } else {
                    Toast.makeText(this, "No matches found", Toast.LENGTH_SHORT).show()
                }
            }
            .addOnFailureListener { e ->
                Toast.makeText(this, "Failed to fetch matches: ${e.message}", Toast.LENGTH_SHORT).show()
            }
    }


}