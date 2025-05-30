package au.edu.utas.kit305.tutorial05


data class Action(
    val player: String = "",
    val team: String = "",
    val quarter: String = "",
    val actionType: String = "",
    val timestamp: Long = 0
)

