package au.edu.utas.kit305.tutorial05

import com.google.firebase.firestore.Exclude

data class Match(

    var match_id: String? = null,  //
    var team1: String? = null,
    var team2: String? = null,
    var score1: String? = null,
    var score2: String? = null,
    var date: String? = null,
    var location: String? = null,
    var startTimestamp: Long = 0L,
    var imageBase64: String = ""
)
