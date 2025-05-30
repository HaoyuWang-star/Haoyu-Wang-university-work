package au.edu.utas.kit305.tutorial05

import android.annotation.SuppressLint
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.util.Log
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import au.edu.utas.kit305.tutorial05.databinding.ActivityViewPlayersBinding
import au.edu.utas.kit305.tutorial05.databinding.MyListPlayersBinding
import com.bumptech.glide.Glide
import com.google.firebase.Firebase
import com.google.firebase.firestore.firestore
import com.google.firebase.firestore.toObject
import java.io.File
import android.util.Base64

const val FIREBASE_TAG_PLAYERS = "FirebaseLogging_Players"
const val PLAYER_INDEX = "Player_Index"
val players = mutableListOf<Player>()
class ViewPlayers : AppCompatActivity() {
    private val filteredPlayers = mutableListOf<Player>()
    private lateinit var ui: ActivityViewPlayersBinding
    //get specific team players
    fun loadPlayersByTeam(teamName: String) {
        ui.lblPlayerCount.text = "Loading..."
        val playersCollection = Firebase.firestore.collection("players")

        playersCollection
            .whereEqualTo("team_belong", teamName)
            .get()
            .addOnSuccessListener { result ->
                Log.d("DEBUG", "Players found: ${result.size()}")  // Print the number of players
                players.clear()
                filteredPlayers.clear()

                for (document in result) {
                    val player = document.toObject<Player>()
                    player.player_id = document.id
                    players.add(player)
                    Log.d("DEBUG", "Loaded Player: ${player.name}, ID: ${player.player_id}")  // Print Player Information
                }

                filteredPlayers.addAll(players)
                ui.myPlayersList.adapter = PlayerAdapter(filteredPlayers)
                Log.d("DEBUG", "Adapter initialized with ${filteredPlayers.size} players")  // Ensure that data is available when the adapter is initialised
                ui.myPlayersList.adapter?.notifyDataSetChanged() // Ensure the UI is refreshed immediately
                // update UI
                if (players.size < 2) {
                    ui.lblPlayerCount.text = "${players.size} Players found in $teamName\nTeam needs at least two players to start the match!"
                } else {
                    ui.lblPlayerCount.text = "${players.size} Players found in $teamName"
                }
            }
            .addOnFailureListener { e ->
                Log.e("DEBUG", "Error loading players", e)
                ui.lblPlayerCount.text = "Failed to load players"
            }
    }
    override fun onResume() {
        super.onResume()
        val teamName = intent.getStringExtra("TEAM_NAME") ?: ""
        if (teamName.isNotEmpty()) {
            Log.d("DEBUG", "onResume: Reloading players for team: $teamName")
            loadPlayersByTeam(teamName)  // reload the data
        }
    }
    @SuppressLint("SetTextI18n", "NotifyDataSetChanged")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ui = ActivityViewPlayersBinding.inflate(layoutInflater)
        setContentView(ui.root)

        //vertical list
        ui.myPlayersList.layoutManager = LinearLayoutManager(this)
        ui.myPlayersList.setHasFixedSize(true) // Improved performance

        //get db connection
        val db = Firebase.firestore
        Log.d("FIREBASE", "Firebase connected: ${db.app.name}")



        //add some data (comment this out after running the program once and confirming your data is there)
        val lotr = Player(
            player_id = "1",
            name = "David smith",
            team_belong = "Carlton",
            age = 24,
            imageBase64= ""
        )
        val playersCollection = db.collection("players")
        //playersCollection
        //.add(lotr)
        //.addOnSuccessListener {
        //lotr.player_id = it.id
        //Log.d(FIREBASE_TAG_PLAYERS, "Document created with id ${it.id}")
        //}
        //.addOnFailureListener {
        //Log.e(FIREBASE_TAG_PLAYERS, "Error writing document", it)
        //}

        ui.lblPlayerCount.text = "${filteredPlayers.size} Players"





        val teamName = intent.getStringExtra("TEAM_NAME") ?: ""
        Log.d("DEBUG", "Team Name: $teamName")  // Check if teamName is empty
        if (teamName.isNotEmpty()) {
            loadPlayersByTeam(teamName) // Ensure that it is called correctly
        } else {
            Log.e("DEBUG", "No team name provided")
        }



        ui.searchBox.addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) {
                (ui.myPlayersList.adapter as? PlayerAdapter)?.filter(s.toString())
            }

            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}

            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
        })

        ui.searchButton.setOnClickListener {
            val query = ui.searchBox.text.toString().trim()
            (ui.myPlayersList.adapter as? PlayerAdapter)?.filter(query)
        }




// Navigate to PlayerCreate Activity when "Create a new Player" button is clicked
        ui.btnCreatePlayer.setOnClickListener {
           val intent = Intent(this, PlayerCreate::class.java)
            startActivity(intent)
        }
        val MATCH_ID = intent.getStringExtra("MATCH_ID")
        ui.btnViewContribution.setOnClickListener {
            val intent = Intent(this, ViewContribution::class.java)
            intent.putExtra("Match_ID", MATCH_ID) // Pass match ID
            intent.putExtra("TEAM_NAME", teamName) // Pass team name
            startActivity(intent)
        }

        ui.Close.setOnClickListener {
            finish()
        }

    }
    // ViewHolder class
    inner class PlayerHolder(var ui: MyListPlayersBinding) : RecyclerView.ViewHolder(ui.root)

    // RecyclerView Adapter for Players
    inner class PlayerAdapter(private val players: MutableList<Player>) :
        RecyclerView.Adapter<PlayerHolder>() {
        private var filteredPlayers = mutableListOf<Player>().apply { addAll(players) }
        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): PlayerHolder {
            val binding = MyListPlayersBinding.inflate(LayoutInflater.from(parent.context), parent, false)
            return PlayerHolder(binding) // Correctly passing binding
        }

        override fun onBindViewHolder(holder: PlayerHolder, position: Int) {
            val player = filteredPlayers[position] // check filteredPlayers position

            holder.ui.txtPlayer.text = player.name
            holder.ui.txtAge.text = player.age.toString()

            // Pass the correct player_id
            holder.ui.btnEdit.setOnClickListener {
                val i = Intent(holder.ui.root.context, PlayerDetails::class.java)

                //  Find this player's index in `players`, not `filteredPlayers`
                val originalIndex = players.indexOfFirst { it.player_id == player.player_id }

                if (originalIndex != -1) {
                    i.putExtra(PLAYER_INDEX, originalIndex) // Pass the original index
                } else {
                    i.putExtra(PLAYER_INDEX, position) // backup index
                }

                holder.ui.root.context.startActivity(i)
            }

            holder.ui.btnDelete.setOnClickListener {
                val playerToDelete = filteredPlayers[position]  //  Get right `player`

                if (!playerToDelete.name.isNullOrEmpty() && !playerToDelete.player_id.isNullOrEmpty()) {  // Confirm player_id is not null
                    val db = Firebase.firestore

                    AlertDialog.Builder(holder.ui.root.context)
                        .setTitle("Confirm Deletion")
                        .setMessage("Are you sure you want to delete player: ${playerToDelete.name}?")
                        .setPositiveButton("Yes") { _, _ ->
                            db.collection("players")
                                .document(playerToDelete.player_id!!)  // Using `!!` confirm it is not null
                                .delete()
                                .addOnSuccessListener {
                                    Log.d(FIREBASE_TAG_PLAYERS, "Player deleted: ${playerToDelete.name}")
                                    Toast.makeText(holder.ui.root.context, "Player deleted", Toast.LENGTH_SHORT).show()

                                    // Remove it from `players` first.
                                    players.removeIf { it.player_id == playerToDelete.player_id }
                                    // Remove it from `filteredPlayers` again.
                                    filteredPlayers.removeAt(position)

                                    notifyItemRemoved(position)
                                    notifyItemRangeChanged(position, filteredPlayers.size)
                                }
                        }
                        .setNegativeButton("No", null)
                        .show()
                } else {
                    Toast.makeText(holder.ui.root.context, "Error: Player ID is missing!", Toast.LENGTH_SHORT).show()
                }
            }

            val imageBytes = Base64.decode(player.imageBase64, Base64.DEFAULT)
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            holder.ui.imgPlayer.setImageBitmap(bitmap)


            // Make sure you get the right picture
            Glide.with(holder.ui.root.context)
                .load(bitmap)
                .placeholder(R.drawable.img)
                .into(holder.ui.imgPlayer)

        }



        override fun getItemCount(): Int {
            return filteredPlayers.size  // This should return `filteredPlayers.size`.Sam
        }

        fun filter(query: String) {
            filteredPlayers.clear()

            if (query.isEmpty()) {
                filteredPlayers.addAll(players)
            } else {
                val lowerCaseQuery = query.lowercase()
                filteredPlayers.addAll(
                    players.filter { it.name?.lowercase()?.contains(lowerCaseQuery) == true }
                )
            }

            notifyDataSetChanged() // Confirm `RecyclerView`  update
        }



    }
}


