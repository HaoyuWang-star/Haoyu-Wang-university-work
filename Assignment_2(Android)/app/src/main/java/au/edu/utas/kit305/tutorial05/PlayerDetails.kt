package au.edu.utas.kit305.tutorial05

import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.widget.EditText
import androidx.appcompat.app.AppCompatActivity
import au.edu.utas.kit305.tutorial05.databinding.ActivityPlayerDetailsBinding
import com.google.firebase.Firebase
import com.google.firebase.firestore.firestore
import java.io.File
import android.util.Base64

const val FIREBASE_TAG_PLAYERDETAIL = "FirebaseLogging_PlayerDetail"
class PlayerDetails : AppCompatActivity() {
    private lateinit var ui : ActivityPlayerDetailsBinding // Ensure correct binding file
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ui = ActivityPlayerDetailsBinding.inflate(layoutInflater) // Ensure correct binding
        setContentView(ui.root)

//get player object using id from intent
        val playerID = intent.getIntExtra(PLAYER_INDEX, -1)
        val playerObject = players[playerID]
//TODO: you'll need to set txtTitle, txtYear, txtDuration yourself
        if (playerObject.imageBase64.isNotBlank()) {
            try {
                val imageBytes = Base64.decode(playerObject.imageBase64, Base64.DEFAULT)
                val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                ui.imgTeam.setImageBitmap(bitmap)
            } catch (e: Exception) {
                Log.e("ImageDecode", "Failed to decode Base64 image", e)
                ui.imgTeam.setImageResource(R.drawable.img) // fallback image
            }
        } else {
            ui.imgTeam.setImageResource(R.drawable.img) // fallback image when empty
        }

        val Name=playerObject.name
        val txtName = findViewById<EditText>(R.id.txtName)
        txtName.setText(Name.toString())

        val Age=playerObject.age
        val txtAge = findViewById<EditText>(R.id.txtAge)
        txtAge.setText(Age.toString())

        val Team=playerObject.team_belong
        val txtTeamBelong = findViewById<EditText>(R.id.txtTeamBelong)
        txtTeamBelong.setText(Team.toString())

            val db = Firebase.firestore
            val playersCollection = db.collection("players")

            ui.btnUpdate.setOnClickListener {
                //get the user input
                playerObject.name = ui.txtName.text.toString().trim()
                playerObject.age = ui.txtAge.text.toString().toIntOrNull() // which returns null if the conversion fails.
                playerObject.team_belong = ui.txtTeamBelong.text.toString().trim()

                //update the database
                playersCollection.document(playerObject.player_id!!)
                    .set(playerObject)
                    .addOnSuccessListener {
                        Log.d(FIREBASE_TAG_PLAYERDETAIL, "Successfully updated player ${playerObject.player_id}")
                        //return to the list
                        finish()
                    }
            }
        ui.btnCancel.setOnClickListener {
            finish()
        }
        }

}