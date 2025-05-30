class PlayerStats {
  final String playerName;
  int totalKickGoals;
  int totalKickBehinds;
  int totalKickNoScore;
  int totalMarks;
  int totalTackles;
  int totalHandballBehinds;
  int totalHandballNoScore;

  PlayerStats({
    required this.playerName,
    this.totalKickGoals = 0,
    this.totalKickBehinds = 0,
    this.totalKickNoScore = 0,
    this.totalMarks = 0,
    this.totalTackles = 0,
    this.totalHandballBehinds = 0,
    this.totalHandballNoScore = 0,
  });

  int get totalScore {
    return (totalKickGoals * 6) + totalKickBehinds + totalHandballBehinds;
  }

  int get totalKicks => totalKickGoals + totalKickBehinds + totalKickNoScore;
  int get totalHandballs => totalHandballBehinds + totalHandballNoScore;
  int get totalBehinds => totalKickBehinds + totalHandballBehinds;
}
