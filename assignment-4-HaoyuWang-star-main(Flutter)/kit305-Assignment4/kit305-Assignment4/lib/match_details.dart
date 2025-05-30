import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'match.dart';
import 'team_record.dart';
import 'add_action_page.dart';
import 'match_view_page.dart';
import 'match_history_page.dart';
import 'player_compare_page.dart';

class MatchDetailPage extends StatefulWidget {
  final Match match;

  const MatchDetailPage({Key? key, required this.match}) : super(key: key);

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  late Match match;

  @override
  void initState() {
    super.initState();
    match = widget.match;
  }

  Widget scoreText(String score, bool isWinning) {
    return Text(
      score.isEmpty ? "0.0 (0)" : score,
      style: TextStyle(
        fontWeight: isWinning ? FontWeight.bold : FontWeight.normal,
        color: isWinning ? Colors.red : Colors.black,
        fontSize: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${match.team1} vs ${match.team2}"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (match.imageBase64 != null && match.imageBase64!.isNotEmpty)
              Image.memory(
                base64Decode(match.imageBase64!),
                height: 180,
                fit: BoxFit.cover,
              )
            else
              Image.asset("assets/placeholder.png", height: 180),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Date: ${match.date ?? 'N/A'}"),
                Text("Location: ${match.location ?? 'N/A'}"),
              ],
            ),

            const SizedBox(height: 12),

            /// Real-time Score StreamBuilder
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matches')
                  .doc(match.id)
                  .collection('history_actions')
                  .snapshots(),
              builder: (context, snapshot) {
                int team1Goals = 0, team1Behinds = 0;
                int team2Goals = 0, team2Behinds = 0;

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final actionType = data['actionType'] ?? '';
                    final team = data['team'] ?? '';

                    if (actionType == 'Kick Goal Scored (6 Points)') {
                      if (team == match.team1) team1Goals++;
                      else team2Goals++;
                    } else if (actionType == 'Kick Behind Scored (1 Point)' || actionType == 'Handball Behind Score (1 Point)') {
                      if (team == match.team1) team1Behinds++;
                      else team2Behinds++;
                    }
                  }
                }

                final team1Total = team1Goals * 6 + team1Behinds;
                final team2Total = team2Goals * 6 + team2Behinds;

                final team1Score = "${team1Goals}.${team1Behinds} ($team1Total)";
                final team2Score = "${team2Goals}.${team2Behinds} ($team2Total)";

                final team1Wins = team1Total > team2Total;
                final team2Wins = team2Total > team1Total;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(match.team1 ?? "Team 1",
                            style: TextStyle(
                                fontWeight: team1Wins ? FontWeight.bold : FontWeight.normal)),
                        scoreText(team1Score, team1Wins),
                        ElevatedButton(
                          onPressed: () {
                            if (match.team1 == null || match.id == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeamRecordPage(
                                  teamName: match.team1!,
                                  matchID: match.id!,
                                ),
                              ),
                            );
                          },
                          child: Text("View ${match.team1}"),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(match.team2 ?? "Team 2",
                            style: TextStyle(
                                fontWeight: team2Wins ? FontWeight.bold : FontWeight.normal)),
                        scoreText(team2Score, team2Wins),
                        ElevatedButton(
                          onPressed: () {
                            if (match.team2 == null || match.id == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeamRecordPage(
                                  teamName: match.team2!,
                                  matchID: match.id!,
                                ),
                              ),
                            );
                          },
                          child: Text("View ${match.team2}"),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: 520,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AddActionPage(
                      matchID: match.id!,
                      team1Name: match.team1!,
                      team2Name: match.team2!,
                    ),
                  ));
                },
                child: const Text("Add Player Action"),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: 520,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MatchViewPage(
                      matchID: match.id!,
                      team1Name: match.team1!,
                      team2Name: match.team2!,
                    ),
                  ));
                },
                child: const Text("View Quarter Graph"),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: 520,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MatchHistoryPage(
                      matchID: match.id!,
                      team1Name: match.team1!,
                      team2Name: match.team2!,
                    ),
                  ));
                },
                child: const Text("View Match History"),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: 520,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PlayerComparePage(
                      matchID: match.id!,
                      team1Name: match.team1!,
                      team2Name: match.team2!,
                    ),
                  ));
                },
                child: const Text("Compare Players"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
