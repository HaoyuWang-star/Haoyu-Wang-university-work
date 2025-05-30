package au.edu.utas.kit305.tutorial05

import android.annotation.SuppressLint
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Typeface
import android.os.Bundle
import android.util.Base64
import android.util.Log
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import au.edu.utas.kit305.tutorial05.databinding.ActivityMainBinding
import au.edu.utas.kit305.tutorial05.databinding.MyListItemBinding
import com.bumptech.glide.Glide
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.Tasks
import com.google.firebase.Firebase
import com.google.firebase.firestore.QuerySnapshot
import com.google.firebase.firestore.firestore
import com.google.firebase.firestore.toObject
const val FIREBASE_TAG_MAIN = "FirebaseLogging_Main"
const val MATCH_INDEX = "Match_Index"
val items = mutableListOf<Match>()

class MainActivity : AppCompatActivity() {

    private lateinit var ui: ActivityMainBinding
    override fun onResume() {
        super.onResume()
        ui.myList.adapter?.notifyDataSetChanged() //without a more complicated set-up, we can't be more specific than "dataset changed"
    }
    @SuppressLint("SetTextI18n", "NotifyDataSetChanged")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ui = ActivityMainBinding.inflate(layoutInflater)
        setContentView(ui.root)

        //vertical list
        ui.myList.layoutManager = LinearLayoutManager(this)
        ui.myList.setHasFixedSize(true) // Optional: Improves performance

        //get db connection
        val db = Firebase.firestore
        Log.d("FIREBASE", "Firebase connected: ${db.app.name}")




        val matchesCollection = db.collection("matches")

        ui.lblMatchCount.text = "${items.size} Matches"
        ui.myList.adapter = MatchAdapter(matches = items)

        //get all matches
        ui.lblMatchCount.text = "Loading..."

        matchesCollection.get()
            .addOnSuccessListener { result ->
                items.clear()
                val matchTasks = mutableListOf<Task<QuerySnapshot>>()

                for (document in result) {
                    val match = document.toObject<Match>()
                    match.match_id = document.id
                    items.add(match)

                    // Fetch match-specific history actions
                    val Match_ID=match.match_id
                    val task = db.collection("matches").document("$Match_ID").collection("history_actions").get()

                    matchTasks.add(task)
                }

                Tasks.whenAllSuccess<QuerySnapshot>(matchTasks)
                    .addOnSuccessListener { results ->
                        for ((index, documents) in results.withIndex()) {
                            val match = items[index]
                            var team1Goals = 0
                            var team1Behinds = 0
                            var team2Goals = 0
                            var team2Behinds = 0

                            for (document in documents) {
                                val actionType = document.getString("actionType") ?: continue
                                val team = document.getString("team") ?: continue

                                when (actionType) {
                                    "Kick Goal Scored (6 Points)" -> {
                                        if (team == match.team1) team1Goals++ else team2Goals++
                                    }
                                    "Kick Behind Scored (1 Point)", "Handball Behind Score (1 Point)" -> {
                                        if (team == match.team1) team1Behinds++ else team2Behinds++
                                    }
                                }
                            }

                            val team1Total = (team1Goals * 6) + team1Behinds
                            val team2Total = (team2Goals * 6) + team2Behinds

                            // Update match scores
                            match.score1 = "$team1Goals.$team1Behinds ($team1Total)"
                            match.score2 = "$team2Goals.$team2Behinds ($team2Total)"
                        }

                        ui.lblMatchCount.text = "${items.size} Matches found"
                        (ui.myList.adapter as MatchAdapter).notifyDataSetChanged()
                    }
                    .addOnFailureListener { e ->
                        Log.e(FIREBASE_TAG_MAIN, "Failed to fetch history actions: ${e.message}")
                    }
            }

// Navigate to MatchCreate Activity when "Create a new match" button is clicked
        ui.btncreate.setOnClickListener {
            val intent = Intent(this, MatchCreate::class.java)
            startActivity(intent)
        }

    }
    // ViewHolder class
    inner class MatchHolder(var ui: MyListItemBinding) : RecyclerView.ViewHolder(ui.root)

    // RecyclerView Adapter for Matches
    inner class MatchAdapter(private val matches: MutableList<Match>) :
        RecyclerView.Adapter<MatchHolder>() {

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MatchHolder {
            val binding = MyListItemBinding.inflate(LayoutInflater.from(parent.context), parent, false)
            return MatchHolder(binding) // Correctly passing binding
        }

        override fun onBindViewHolder(holder: MatchHolder, position: Int) {
            val match = matches[position] // Get match data at position

            // Bind data to UI
            holder.ui.txtTeam1.text = match.team1
            holder.ui.txtTeam2.text = match.team2
            holder.ui.txtScore1.text = match.score1 ?: "0.0 (0)"
            holder.ui.txtScore2.text = match.score2 ?: "0.0 (0)"
            holder.ui.txtDate.text = match.date
            holder.ui.txtLocation.text = match.location
            // Bolding higher scoring teams and scores

            // Extract total scores from "Goals.Behinds (Total)" format
            fun extractTotalScore(score: String?): Int {
                return score?.substringAfter("(")?.substringBefore(")")?.toIntOrNull() ?: 0
            }

            val team1Total = extractTotalScore(match.score1)
            val team2Total = extractTotalScore(match.score2)

            if (team1Total > team2Total) {
                holder.ui.txtTeam1.setTypeface(null, Typeface.BOLD)
                holder.ui.txtScore1.setTypeface(null, Typeface.BOLD)
                holder.ui.txtTeam2.setTypeface(null, Typeface.NORMAL)
                holder.ui.txtScore2.setTypeface(null, Typeface.NORMAL)
            } else if (team2Total > team1Total) {
                holder.ui.txtTeam2.setTypeface(null, Typeface.BOLD)
                holder.ui.txtScore2.setTypeface(null, Typeface.BOLD)
                holder.ui.txtTeam1.setTypeface(null, Typeface.NORMAL)
                holder.ui.txtScore1.setTypeface(null, Typeface.NORMAL)
            } else {
                holder.ui.txtTeam1.setTypeface(null, Typeface.NORMAL)
                holder.ui.txtScore1.setTypeface(null, Typeface.NORMAL)
                holder.ui.txtTeam2.setTypeface(null, Typeface.NORMAL)
                holder.ui.txtScore2.setTypeface(null, Typeface.NORMAL)
            }
            val imageBytes = Base64.decode(match.imageBase64, Base64.DEFAULT)
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            holder.ui.imgTeam.setImageBitmap(bitmap)


            // Make sure you get the right picture
            Glide.with(holder.ui.root.context)
                .load(bitmap)
                .placeholder(R.drawable.carltonvhawthprn)
                .into(holder.ui.imgTeam)

            // Open Match Details on Click
            holder.ui.root.setOnClickListener {
                val i = Intent(holder.ui.root.context, MatchDetails::class.java)
                i.putExtra(MATCH_INDEX, position)
                holder.ui.root.context.startActivity(i)
            }
        }

        override fun getItemCount(): Int {
            return matches.size
        }
    }
}





