package au.edu.utas.kit305.tutorial05  // Ensure this matches your app's package name
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import au.edu.utas.kit305.tutorial05.databinding.ActivityAddActionBinding
import com.google.firebase.firestore.FirebaseFirestore
class ActionAdd : AppCompatActivity() {

    private lateinit var ui: ActivityAddActionBinding
    private lateinit var teams: MutableList<String>
    private lateinit var players: MutableList<String>
    //Ask GPT how to add a calculator for quarter,it allows quarter can change by time when the match was created
    private var currentQuarter: Int = 1
    private var judgingQuarter: Int = 1
    private val quarterDurationMillis =30*1000L //  minutes
    private val maxQuarter = 4
    private var startTimestamp: Long = 0L
    private val handler = android.os.Handler()
    private lateinit var updateQuarterRunnable: Runnable
    private fun loadMatchAndStartQuarterUpdates(matchId: String) {
        val db = FirebaseFirestore.getInstance()
        db.collection("matches").document(matchId).get()
            .addOnSuccessListener { document ->
                startTimestamp = document.getLong("startTimestamp") ?: System.currentTimeMillis()

                updateQuarterRunnable = object : Runnable {
                    override fun run() {
                        val currentTimestamp = System.currentTimeMillis()
                        val elapsedTime = currentTimestamp - startTimestamp
                        currentQuarter = (elapsedTime / quarterDurationMillis).toInt() + 1
                        if (currentQuarter > maxQuarter) {
                            judgingQuarter = currentQuarter
                            currentQuarter = maxQuarter
                        }

                        ui.currentQuarterText.text = "Quarter: $currentQuarter"

                        // Perform the update again
                        handler.postDelayed(this, 1000) // Updated every second
                    }
                }

                // Starting the update loop
                handler.post(updateQuarterRunnable)
            }
    }


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        ui = ActivityAddActionBinding.inflate(layoutInflater)
        setContentView(ui.root)

        teams = mutableListOf()
        players = mutableListOf()

        // Load teams
        loadTeams()

        // Team selection listener
        ui.spinnerTeam.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                loadPlayers(teams[position])
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }

        // Presenting current quarter
        val matchId = intent.getStringExtra("Match_ID") ?: "Unknown"
        loadMatchAndStartQuarterUpdates(matchId)



        // Action buttons
        listOf(
            ui.btnAction1 to "Kick Goal Scored (6 Points)",
            ui.btnAction2 to "Kick Behind Scored (1 Point)",
            ui.btnAction3 to "Kick No Score (0 Points)",
            ui.btnAction4 to "Handball Behind Score (1 Point)",
            ui.btnAction5 to "Mark (Catching the ball)",
            ui.btnAction6 to "Tackle"
        ).forEach { (button, actionType) ->
            button.setOnClickListener { onActionButtonClicked(actionType) }
        }

        Log.d("ActionAddDebug", "ActionAdd Activity Loaded Successfully")
        ui.Close.setOnClickListener {
            val Intent = Intent(this, MainActivity::class.java)
            startActivity(Intent)
        }

    }

    private fun loadTeams() {
        teams.clear()
        val team1Name = intent.getStringExtra("TEAM1_NAME") ?: "Unknown" // get team1
        val team2Name = intent.getStringExtra("TEAM2_NAME") ?: "Unknown" // get team2
        teams.add(team1Name)
        teams.add(team2Name)

        ui.spinnerTeam.adapter = ArrayAdapter(this, android.R.layout.simple_spinner_dropdown_item, teams)
    }

    private fun loadPlayers(teamName: String) {
        val db = FirebaseFirestore.getInstance()
        db.collection("players").whereEqualTo("team_belong", teamName)
            .get()
            .addOnSuccessListener { result ->
                players.clear()
                for (document in result) {
                    val player = document.getString("name") ?: "Unknown"
                    players.add(player)
                }
                ui.spinnerPlayer.adapter = ArrayAdapter(this, android.R.layout.simple_spinner_dropdown_item, players)
            }
            .addOnFailureListener { e ->
                Log.e("FIRESTORE_ERROR", "Failed to load players", e)
            }
    }
    private fun onActionButtonClicked(actionType: String) {
        if (judgingQuarter > maxQuarter) {
            // Display a message if the match is over
            Toast.makeText(this, "The match has ended!", Toast.LENGTH_SHORT).show()
            return
        }

        insertActionData(actionType)
    }
    private fun insertActionData(actionType: String) {
        val db = FirebaseFirestore.getInstance()
        val selectedPlayer = ui.spinnerPlayer.selectedItem?.toString() ?: ""
        val selectedTeam = ui.spinnerTeam.selectedItem?.toString() ?: ""
        val selectedQuarter = currentQuarter.toString()

        if (selectedPlayer.isEmpty() || selectedTeam.isEmpty() || selectedQuarter.isEmpty()) {
            Toast.makeText(this, "Please select team, player, and quarter", Toast.LENGTH_SHORT).show()
            return
        }

        val actionData = hashMapOf(
            "player" to selectedPlayer,
            "team" to selectedTeam,
            "quarter" to selectedQuarter,
            "actionType" to actionType,
            "timestamp" to System.currentTimeMillis()
        )
        val matchId = intent.getStringExtra("Match_ID") ?: "Unknown" // get match document ID
        db.collection("matches").document("$matchId").collection("history_actions").add(actionData)
            .addOnSuccessListener {
                Toast.makeText(this, "Action $actionType recorded", Toast.LENGTH_SHORT).show()
            }
            .addOnFailureListener { e ->
                Log.e("ACTION_ERROR", "Failed to insert action data", e)
                Toast.makeText(this, "Failed to record action", Toast.LENGTH_SHORT).show()
            }
    }
    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(updateQuarterRunnable)
    }
}
