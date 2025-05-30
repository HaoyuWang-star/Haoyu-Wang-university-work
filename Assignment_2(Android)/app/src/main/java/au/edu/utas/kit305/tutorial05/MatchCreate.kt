package au.edu.utas.kit305.tutorial05

import android.content.Intent
import android.net.Uri
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.widget.Toast
import au.edu.utas.kit305.tutorial05.databinding.ActivityMatchCreateBinding
import com.google.firebase.Firebase
import com.google.firebase.firestore.firestore
import java.io.File
import java.io.IOException
import android.util.Base64

class MatchCreate : AppCompatActivity() {
    private lateinit var ui : ActivityMatchCreateBinding // Ensure correct binding file
    private val PICK_IMAGE_REQUEST = 1
    private var imageBase64: Uri? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ui = ActivityMatchCreateBinding.inflate(layoutInflater) // Ensure correct binding
        setContentView(ui.root)

        val db = Firebase.firestore
        val matchesCollection = db.collection("matches")
        // Open image picker
        ui.imgTeam.setOnClickListener {
            val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            startActivityForResult(intent, PICK_IMAGE_REQUEST)
        }

        // Save match with image
        ui.btnSave.setOnClickListener {
            if (imageBase64 != null) {
                uploadImageAndSaveMatch()
            } else {
                saveMatch(null)
            }
        }

        ui.btnCancel.setOnClickListener {
            val Intent = Intent(this, MainActivity::class.java)
            startActivity(Intent) }

    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_IMAGE_REQUEST && resultCode == RESULT_OK && data != null) {
            imageBase64 = data.data
            ui.imgTeam.setImageURI(imageBase64) // Preview image
        }
    }
    private fun imageUriToBase64(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri)
            val byteArray = inputStream?.readBytes()
            inputStream?.close()
            Base64.encodeToString(byteArray, Base64.DEFAULT)
        } catch (e: IOException) {
            Log.e("BASE64_CONVERT_ERROR", "Failed to convert image to Base64", e)
            null
        }
    }

    private fun uploadImageAndSaveMatch() {
        if (imageBase64 != null) {
            val base64Image = imageUriToBase64(imageBase64!!)
            if (base64Image != null) {
                saveMatch(base64Image) // Save match with Base64 string instead of file path
            } else {
                Toast.makeText(this, "Failed to convert image", Toast.LENGTH_SHORT).show()
            }
        } else {
            saveMatch(null) // If no image selected
        }
    }




    private fun saveMatch(imageBase64: String?) {
        val team1 = ui.txtTeam1.text.toString()
        val team2 = ui.txtTeam2.text.toString()
        val date = ui.txtDate.text.toString()
        val location = ui.txtLocation.text.toString()
        val startTimestamp = System.currentTimeMillis()
        val match = Match(
            team1 = team1, team2 = team2, date = date, location = location,startTimestamp =startTimestamp, imageBase64 = imageBase64 ?: ""
        )

        val matchesCollection = Firebase.firestore.collection("matches")
        matchesCollection.add(match)
            .addOnSuccessListener { documentReference ->
                // Under the matches documents create history_actions subset
                documentReference.collection("history_actions").add(hashMapOf(
                    "message" to "Match started"
                ))
                Toast.makeText(this, "Match saved", Toast.LENGTH_SHORT).show()
                finish()
            }
            .addOnFailureListener {
                Toast.makeText(this, "Failed to save match", Toast.LENGTH_SHORT).show()
            }
        items.add(match)

    }
}
