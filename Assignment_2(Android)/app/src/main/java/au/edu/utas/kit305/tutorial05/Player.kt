package au.edu.utas.kit305.tutorial05
import com.google.firebase.firestore.Exclude
data class Player(
    var player_id: String? = null,
    var name: String? = null,
    var team_belong: String? = null,
    var age: Int? = null,
    var imageBase64: String = "",
    var kick: Int = 0,
    var handball: Int = 0,
    var tackle: Int = 0,
    var mark: Int = 0,
    var goalScore: Int = 0,
    var behindScore: Int = 0
)
