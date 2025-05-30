package au.edu.utas.kit305.tutorial05
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Typeface
import android.net.Uri
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.TextView
import au.edu.utas.kit305.tutorial05.databinding.ActivityMatchDetailsBinding
import android.util.Base64

class MatchDetails : AppCompatActivity() {
    private lateinit var ui : ActivityMatchDetailsBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ui = ActivityMatchDetailsBinding.inflate(layoutInflater)
        setContentView(ui.root)
        //get movie object using id from intent
        val matchID = intent.getIntExtra(MATCH_INDEX, -1)
        val matchObject = items[matchID]
        //TODO: read in movie details and display on this screen
        if (matchObject.imageBase64.isNotBlank()) {
            try {
                val imageBytes = Base64.decode(matchObject.imageBase64, Base64.DEFAULT)
                val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                ui.imgTeam.setImageBitmap(bitmap)
            } catch (e: Exception) {
                Log.e("ImageDecode", "Failed to decode Base64 image", e)
                ui.imgTeam.setImageResource(R.drawable.img) // fallback image
            }
        } else {
            ui.imgTeam.setImageResource(R.drawable.img) // fallback image when empty
        }


        val Team1 = matchObject.team1
        val txtTeam1 = findViewById<TextView>(R.id.txtTeam1)
        txtTeam1.setText(Team1) // Right method

        //set the button teamrec to be the teamname in the database
        val Rec1 = matchObject.team1
        val team1rec = findViewById<Button>(R.id.team1rec)
        team1rec.setText(Rec1)

        val Rec2 = matchObject.team2
        val team2rec = findViewById<Button>(R.id.team2rec)
        team2rec.setText(Rec2)

        val Team2 = matchObject.team2
        val txtTeam2 = findViewById<TextView>(R.id.txtTeam2)
        txtTeam2.setText(Team2.toString()) // change int to string type

        val Score1 = matchObject.score1 ?: "0.0 (0)"
        val txtScore1 = findViewById<TextView>(R.id.txtScore1)
        txtScore1.setText(Score1) // change float to string type

        val Score2 = matchObject.score2 ?: "0.0 (0)"
        val txtScore2 = findViewById<TextView>(R.id.txtScore2)
        txtScore2.setText(Score2) // change float to string type

        // Extract total scores from "Goals.Behinds (Total)" format
        fun extractTotalScore(score: String?): Int {
            return score?.substringAfter("(")?.substringBefore(")")?.toIntOrNull() ?: 0
        }

        val team1Total = extractTotalScore(matchObject.score1)
        val team2Total = extractTotalScore(matchObject.score2)
        if (team1Total >team2Total) {
            ui.txtTeam1.setTypeface(null, Typeface.BOLD)
            ui.txtScore1.setTypeface(null, Typeface.BOLD)
            ui.txtTeam2.setTypeface(null, Typeface.NORMAL)
            ui.txtScore2.setTypeface(null, Typeface.NORMAL)
        } else if (team2Total > team1Total) {
            ui.txtTeam2.setTypeface(null, Typeface.BOLD)
            ui.txtScore2.setTypeface(null, Typeface.BOLD)
            ui.txtTeam1.setTypeface(null, Typeface.NORMAL)
            ui.txtScore1.setTypeface(null, Typeface.NORMAL)
        } else {
            ui.txtTeam1.setTypeface(null, Typeface.NORMAL)
            ui.txtScore1.setTypeface(null, Typeface.NORMAL)
            ui.txtTeam2.setTypeface(null, Typeface.NORMAL)
            ui.txtScore2.setTypeface(null, Typeface.NORMAL)
        }
        val Date = matchObject.date
        val txtDate = findViewById<TextView>(R.id.txtDate)
        txtDate.setText(Date) // change int to string type

        val Location = matchObject.location
        val txtLocation = findViewById<TextView>(R.id.txtLocation)
        txtLocation.setText(Location.toString()) // change float to string type

        val team1Name = matchObject.team1  // This can get data from Match
        val team2Name = matchObject.team2 // This can get data from Match
        // Team1 jump
        val Match_ID = matchObject.match_id // This can get data from Match
        findViewById<Button>(R.id.team1rec).setOnClickListener {
            val intent = Intent(this, TeamRecord::class.java)
            intent.putExtra("TEAM_NAME", team1Name) // transmit team1 name
            intent.putExtra("Match_ID", Match_ID)
            startActivity(intent)
        }

        // Team2 jump
        findViewById<Button>(R.id.team2rec).setOnClickListener {
            val intent = Intent(this, TeamRecord::class.java)
            intent.putExtra("TEAM_NAME", team2Name) // transmit team2 name
            intent.putExtra("Match_ID", Match_ID)
            startActivity(intent)
        }

        Log.d("MatchDetail", "Match_ID: $Match_ID")
        findViewById<Button>(R.id.viewmatch).setOnClickListener {
            val intent = Intent(this, MatchView::class.java)
            intent.putExtra("Match_ID", Match_ID)// transmit Match ID confirm this "Match_ID" is align with getStringExtra("Match_ID")
            intent.putExtra("TEAM1_NAME", team1Name) // transmit team1 name
            intent.putExtra("TEAM2_NAME", team2Name)// transmit team2 name
            startActivity(intent)
        }


        ui.btnaction.setOnClickListener {
            val intent = Intent(this, ActionAdd::class.java)
            intent.putExtra("Match_ID", Match_ID)
            intent.putExtra("TEAM1_NAME", team1Name) // transmit team1 name
            intent.putExtra("TEAM2_NAME", team2Name) // transmit team2 name
            startActivity(intent)
        }
        ui.btnMatchHistory.setOnClickListener {
            val intent = Intent(this, MatchHistory::class.java)
            intent.putExtra("Match_ID", Match_ID)
            intent.putExtra("TEAM1_NAME", team1Name) // transmit team1 name
            intent.putExtra("TEAM2_NAME", team2Name)
            startActivity(intent)
        }
        ui.btnCompare.setOnClickListener {
            val intent = Intent(this, PlayerCompareActivity::class.java)
            intent.putExtra("Match_ID", Match_ID)
            intent.putExtra("TEAM1_NAME", team1Name) // transmit team1 name
            intent.putExtra("TEAM2_NAME", team2Name)
            startActivity(intent)
        }

        ui.Close.setOnClickListener {
            val intent = Intent(this, MainActivity::class.java)
            startActivity(intent)
        }

    }
}