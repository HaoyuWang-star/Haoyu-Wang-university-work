package au.edu.utas.kit305.tutorial05
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import au.edu.utas.kit305.tutorial05.databinding.ActivityMatchHistoryBinding
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query

import java.text.SimpleDateFormat
import java.util.*

class MatchHistory : AppCompatActivity() {
    private lateinit var ui: ActivityMatchHistoryBinding
    private val db = FirebaseFirestore.getInstance()
    private val actionList = mutableListOf<Action>()
    private fun shareMatchHistory(matchID: String) {
        val db = FirebaseFirestore.getInstance()

        db.collection("matches").document(matchID).collection("history_actions")
            .get()
            .addOnSuccessListener { result ->
                val actionList = mutableListOf<Map<String, String>>()
                val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
                val stringBuilder = StringBuilder()

                for (document in result) {
                    val timestamp = document.getLong("timestamp")?.toString() ?: "0"

                    val action = mapOf(
                        "player" to (document.getString("player") ?: ""),
                        "actionType" to (document.getString("actionType") ?: ""),
                        "timestamp" to timestamp
                    )

                    actionList.add(action)
                }


                if (actionList.isEmpty()) {
                    Toast.makeText(this, "No actions to share", Toast.LENGTH_SHORT).show()
                    return@addOnSuccessListener
                }
                for (action in actionList) {
                    val player = action["player"] ?: "Unknown Player"
                    val actionType = action["actionType"] ?: "Unknown Action"
                    val timestampStr = action["timestamp"] ?: "0"

                    // Convert timestamp string to long, then to Date
                    val timestamp = timestampStr.toLongOrNull() ?: 0L
                    val date = Date(timestamp)
                    val formattedDate = formatter.format(date)

                    // Append to the final shareable string
                    stringBuilder.append("[$formattedDate] $player - $actionType\n")
                }
                val finalText = stringBuilder.toString()


                try {
                    val sendIntent = Intent().apply {
                        action = Intent.ACTION_SEND
                        putExtra(Intent.EXTRA_TEXT, finalText)
                        type = "text/plain"
                    }
                    startActivity(Intent.createChooser(sendIntent, "Share Match History"))
                } catch (e: Exception) {
                    Log.e("ShareIntent", "Failed to send intent", e)
                    Toast.makeText(this, "Unable to share match history", Toast.LENGTH_SHORT).show()
                }
            }
            .addOnFailureListener { e ->
                Log.e("Firebase", "Error fetching match history", e)
                Toast.makeText(this, "Failed to fetch match history", Toast.LENGTH_SHORT).show()
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ui = ActivityMatchHistoryBinding.inflate(layoutInflater)
        setContentView(ui.root)

        // Setup RecyclerView
        ui.recyclerViewHistory.layoutManager = LinearLayoutManager(this)
        val adapter = MatchHistoryAdapter(actionList)
        ui.recyclerViewHistory.adapter = adapter

        // Load Match History
        val MATCH_ID = intent.getStringExtra("Match_ID") ?: ""
        db.collection("matches").document("$MATCH_ID").collection("history_actions")
            .orderBy("timestamp", Query.Direction.ASCENDING) // Sort by time (oldest first)
            .get()
            .addOnSuccessListener { result ->
                actionList.clear()
                for (document in result) {
                    val action = document.toObject(Action::class.java)
                    actionList.add(action)
                }
                ui.lblActionCount.text = "${actionList.size} Actions found"
                (ui.recyclerViewHistory.adapter as MatchHistoryAdapter).notifyDataSetChanged()
            }
            .addOnFailureListener { e ->
                Log.e("MatchHistory", "Error loading history", e)
            }
        val team1Name = intent.getStringExtra("TEAM1_NAME") ?: ""
        val team2Name = intent.getStringExtra("TEAM2_NAME") ?: ""
        ui.btnWorm.setOnClickListener {
            val intent = Intent(this, ViewWorm::class.java)
            intent.putExtra("Match_ID", MATCH_ID)
            intent.putExtra("TEAM1_NAME", team1Name) // transmit team1 name
            intent.putExtra("TEAM2_NAME", team2Name)
            startActivity(intent)
        }
        ui.btnShare.setOnClickListener {
            Log.d("ShareButton", "Share button clicked")
            Toast.makeText(this, "Sharing...", Toast.LENGTH_SHORT).show()
            shareMatchHistory(MATCH_ID)
        }
        ui.Close.setOnClickListener {
            finish()
        }


    }


}
