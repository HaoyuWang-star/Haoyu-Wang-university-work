import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'worm_graph_page.dart';

class MatchViewPage extends StatefulWidget {
  final String matchID;
  final String team1Name;
  final String team2Name;

  const MatchViewPage({
    Key? key,
    required this.matchID,
    required this.team1Name,
    required this.team2Name,
  }) : super(key: key);

  @override
  _MatchViewPageState createState() => _MatchViewPageState();
}

class _MatchViewPageState extends State<MatchViewPage> {
  String q1Score = "Loading...";
  String q2Score = "Loading...";
  String q3Score = "Loading...";
  String q4Score = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchTeamStats();
  }

  void fetchTeamStats() async {
    final db = FirebaseFirestore.instance;

    final matchDoc = await db.collection("matches").doc(widget.matchID).get();
    if (!matchDoc.exists) {
      showToast("Match not found");
      return;
    }

    final team1 = matchDoc.get("team1");
    final team2 = matchDoc.get("team2");

    final actionsSnapshot = await db
        .collection("matches")
        .doc(widget.matchID)
        .collection("history_actions")
        .get();

    final docs = actionsSnapshot.docs;

    if (docs.isEmpty) {
      setState(() {
        q1Score = q2Score = q3Score = q4Score = "0.0(0)   VS   0.0(0)";
      });
      showToast("No actions data found for match");
      return;
    }

    final scoreMap = <String, Map<String, ScoreData>>{};

    for (final doc in docs) {
      final team = doc.get("team");
      final quarter = doc.get("quarter");
      final actionType = doc.get("actionType");

      scoreMap.putIfAbsent(team, () => {});
      scoreMap[team]!.putIfAbsent(quarter, () => ScoreData());

      switch (actionType) {
        case "Kick Goal Scored (6 Points)":
          scoreMap[team]![quarter]!.kickGoals++;
          break;
        case "Kick Behind Scored (1 Point)":
          scoreMap[team]![quarter]!.kickBehinds++;
          break;
        case "Handball Behind Score (1 Point)":
          scoreMap[team]![quarter]!.handballBehinds++;
          break;
        default:
          break;
      }
    }

    for (int q = 1; q <= 4; q++) {
      final quarterKey = "$q";
      final team1Data = scoreMap[team1]?[quarterKey] ?? ScoreData();
      final team2Data = scoreMap[team2]?[quarterKey] ?? ScoreData();

      final team1Score = team1Data.totalPoints();
      final team2Score = team2Data.totalPoints();

      final scoreText =
          "${team1Data.kickGoals}.${team1Data.behindsTotal()} ($team1Score)   VS   "
          "${team2Data.kickGoals}.${team2Data.behindsTotal()} ($team2Score)";

      setState(() {
        switch (q) {
          case 1:
            q1Score = scoreText;
            break;
          case 2:
            q2Score = scoreText;
            break;
          case 3:
            q3Score = scoreText;
            break;
          case 4:
            q4Score = scoreText;
            break;
        }
      });
    }
  }

  void showToast(String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text(message)));
  }

  void navigateToWormGraph() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WormGraphPage(
          matchID: widget.matchID,
          team1Name: widget.team1Name,
          team2Name: widget.team2Name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.team1Name} VS ${widget.team2Name} Match Quarters"),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,  // Center vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
            children: [
              scoreRow("Quarter 1", q1Score),
              scoreRow("Quarter 2", q2Score),
              scoreRow("Quarter 3", q3Score),
              scoreRow("Quarter 4", q4Score),
              SizedBox(height: 20),
              SizedBox(
                width: 300, // or whatever width you want
                child: ElevatedButton(
                  onPressed: navigateToWormGraph,
                  child: Text("Show Worm Graph"),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width:300 ,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Back"),
                ),)
            ],
          ),
        ),
      ),
    );
  }

  Widget scoreRow(String title, String score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(width: 20),
          Text(score, style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}

// ScoreData helper class
class ScoreData {
  int kickGoals = 0;
  int kickBehinds = 0;
  int handballBehinds = 0;

  int totalPoints() => kickGoals * 6 + kickBehinds + handballBehinds;
  int behindsTotal() => kickBehinds + handballBehinds;
}


