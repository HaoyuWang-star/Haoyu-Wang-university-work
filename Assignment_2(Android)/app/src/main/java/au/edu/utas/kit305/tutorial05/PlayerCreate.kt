package au.edu.utas.kit305.tutorial05

import android.content.Intent
import android.net.Uri
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import au.edu.utas.kit305.tutorial05.databinding.ActivityPlayerCreateBinding
import com.google.firebase.Firebase
import com.google.firebase.firestore.firestore
import kotlinx.coroutines.CoroutineStart
import java.io.File
import java.io.IOException
import android.util.Base64



class PlayerCreate : AppCompatActivity() {
    private lateinit var ui : ActivityPlayerCreateBinding // Ensure correct binding file
    private val PICK_IMAGE_REQUEST = 1
    private var imageBase64: Uri? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ui = ActivityPlayerCreateBinding.inflate(layoutInflater) // Ensure correct binding
        setContentView(ui.root)

        val db = Firebase.firestore
         //Open image picker
        ui.imgTeam.setOnClickListener {
            val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            startActivityForResult(intent, PICK_IMAGE_REQUEST)
        }

        // Save match with image
        ui.btnSave.setOnClickListener {
            AlertDialog.Builder(this)
                .setTitle("Confirm Create player")
                .setMessage("Are you sure you want to create this player?")
                .setPositiveButton("Yes") { _, _ ->
                    if (imageBase64 != null) {
                        uploadImageAndSavePlayer()
                    } else {
                        savePlayer(null)
                    }
                }
                .setNegativeButton("No", null) // no action close the pop up window
                .show()
        }


        ui.btnCancel.setOnClickListener {
            finish()
        }
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
            Base64.encodeToString(byteArray, Base64.DEFAULT) // Make sure to import android.util.Base64
        } catch (e: IOException) {
            Log.e("BASE64_CONVERT_ERROR", "Failed to convert image to Base64", e)
            null
        }
    }


    private fun uploadImageAndSavePlayer() {
        if (imageBase64 != null) {
            val base64String = imageUriToBase64(imageBase64!!)
            if (base64String != null) {
                savePlayer(base64String)
            } else {
                Toast.makeText(this, "Failed to convert image", Toast.LENGTH_SHORT).show()
            }
        }
    }





    private fun savePlayer(imageBase64: String?) {
        val name = ui.txtName.text.toString()
        val age = ui.txtAge.text.toString().toIntOrNull() ?: 0
        val team_belong = ui.txtTeamBelong.text.toString()

        val player = Player(
            name = name, age = age, team_belong = team_belong, imageBase64 = imageBase64 ?: ""
        )

        val playersCollection = Firebase.firestore.collection("players")
        playersCollection.add(player)
            .addOnSuccessListener {
                Toast.makeText(this, "Player saved", Toast.LENGTH_SHORT).show()
                finish()
            }
            .addOnFailureListener {
                Toast.makeText(this, "Failed to save player", Toast.LENGTH_SHORT).show()
            }
        players.add(player)

    }
}
