import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_players_page.dart';


class TeamRecordPage extends StatefulWidget {
  final String teamName;
  final String matchID;

  const TeamRecordPage({
    super.key,
    required this.teamName,
    required this.matchID,
  });

  @override
  State<TeamRecordPage> createState() => _TeamRecordPageState();
}

class _TeamRecordPageState extends State<TeamRecordPage> {
  int totalDisposals = 0;
  int totalMarks = 0;
  int totalTackles = 0;
  int totalKickGoals = 0;
  int totalKickBehinds = 0;
  int totalHandballBehinds = 0;

  @override
  void initState() {
    super.initState();
    assert(widget.matchID.isNotEmpty, 'matchID must not be empty');
    assert(widget.teamName.isNotEmpty, 'teamName must not be empty');
    print('matchID: ${widget.matchID}');
    print('teamName: ${widget.teamName}');
    fetchTeamStats();
  }


  Future<void> fetchTeamStats() async {
    final db = FirebaseFirestore.instance;
    final matchesSnapshot = await db.collection('matches').get();


    for (var matchDoc in matchesSnapshot.docs) {
      final historySnapshot = await db
          .collection('matches')
          .doc(matchDoc.id)
          .collection('history_actions')
          .where('team', isEqualTo: widget.teamName)
          .get();

      for (var doc in historySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final actionType = data['actionType']?.toString() ?? '';
        print("Action: ${doc.data()}");
        switch (actionType) {
          case "Kick Goal Scored (6 Points)":
            totalKickGoals++;
            break;
          case "Kick Behind Scored (1 Point)":
            totalKickBehinds++;
            break;
          case "Handball Behind Score (1 Point)":
            totalHandballBehinds++;
            break;
          case "Mark (catching the ball)":
            totalMarks++;
            break;
          case "Tackle":
            totalTackles++;
            break;
        }

        if (actionType.contains("Kick") || actionType.contains("Handball")) {
          totalDisposals++;
        }
      }
    }
    print("Fetching stats for team ${widget.teamName}, matchID: ${widget.matchID}");

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final totalBehind = totalKickBehinds + totalHandballBehinds;
    final totalScore = (totalKickGoals * 6) + totalBehind;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.teamName.isEmpty ? 'Unknown Team' : widget.teamName} Stats"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Center(
                  child: Text(
                    "${widget.teamName} Stats to be shown:",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // set in the left side
                    children: [
                      Text(
                        "Disposals (Kicks + Handballs): $totalDisposals",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "Marks: $totalMarks",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "Tackles: $totalTackles",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "Score: Goals.Behinds (Total): $totalKickGoals.$totalBehind ($totalScore)",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width:200 ,
                            child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewPlayersPage(
                                    matchID: widget.matchID!,
                                    teamName: widget.teamName!,
                                  ),

                                ),
                              );
                            },
                            child: const Text("View players' detail"),
                          ),
                          ),

                          const SizedBox(width: 20),
                          SizedBox(
                            width:100 ,
                            child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Back"),
                          ),)

                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
