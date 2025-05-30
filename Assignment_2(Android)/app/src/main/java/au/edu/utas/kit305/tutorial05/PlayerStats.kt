package au.edu.utas.kit305.tutorial05

data class PlayerStats(
    val playerName: String,
    var totalKickGoals: Int, // Total kicks that scored goals (6 points)
    var totalKickBehinds: Int, // Total kicks that scored behinds (1 point)
    var totalKickNoScore: Int,
    var totalHandballBehinds: Int, // Total handballs that scored behinds (1 point)
    var totalMarks: Int,
    var totalTackles: Int,
    var totalScore: Int // Total score calculated based on actions
) {
    // Helper function to calculate the total score
    fun calculateTotalScore(): Int {
        return (totalKickGoals * 6) + totalKickBehinds + totalHandballBehinds
    }
}


