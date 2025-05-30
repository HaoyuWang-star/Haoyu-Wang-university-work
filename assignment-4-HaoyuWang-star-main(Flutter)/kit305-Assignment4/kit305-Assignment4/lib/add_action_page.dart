import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tutorial_3/match.dart';
import 'package:provider/provider.dart';

class AddActionPage extends StatefulWidget {
  final String matchID;
  final String team1Name;
  final String team2Name;

  const AddActionPage({
    Key? key,
    required this.matchID,
    required this.team1Name,
    required this.team2Name,
  }) : super(key: key);

  @override
  _AddActionPageState createState() => _AddActionPageState();
}

class _AddActionPageState extends State<AddActionPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  late List<String> teams;
  List<String> players = [];
  String? selectedTeam;
  String? selectedPlayer;

  int currentQuarter = 1;
  int judgingQuarter = 1;
  final int maxQuarter = 4;
  final int quarterDurationSeconds = 30;
  double startTimestamp = 0;
  Timer? quarterTimer;

  bool matchStarted = false;
  bool awaitingScoringOption = false;
  String? lastBaseAction;
  String? lastActionTeam;

  @override
  void initState() {
    super.initState();
    teams = [widget.team1Name, widget.team2Name];
    selectedTeam = teams.first;
    loadMatchAndStartQuarterUpdates();
    loadPlayersFor(selectedTeam!);
  }

  void loadMatchAndStartQuarterUpdates() async {
    DocumentSnapshot doc = await db.collection('matches').doc(widget.matchID).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final millis = data['startTimestamp'];
      if (millis is int || millis is double) {
        startTimestamp = (millis as num).toDouble() / 1000.0;
      }

      if (startTimestamp == 0) {
        matchStarted = false;
        currentQuarter = 1;
        return;
      }

      matchStarted = true;
      quarterTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final elapsed = DateTime.now().millisecondsSinceEpoch / 1000.0 - startTimestamp;
        setState(() {
          currentQuarter = (elapsed / quarterDurationSeconds).floor() + 1;
          if (currentQuarter > maxQuarter) {
            judgingQuarter = currentQuarter;
            currentQuarter = maxQuarter;
            stopQuarterTimer();
          }
        });
      });
    }
  }

  void stopQuarterTimer() {
    quarterTimer?.cancel();
    quarterTimer = null;
  }

  void startMatch() {
    setState(() {
      startTimestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;
      currentQuarter = 1;
      judgingQuarter = 1;
      matchStarted = true;
    });

    db.collection('matches').doc(widget.matchID).update({
      'startTimestamp': (startTimestamp * 1000).toInt(),
    });

    quarterTimer = Timer.periodic(Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().millisecondsSinceEpoch / 1000.0 - startTimestamp;
      setState(() {
        currentQuarter = (elapsed / quarterDurationSeconds).floor() + 1;
        if (currentQuarter > maxQuarter) {
          judgingQuarter = currentQuarter;
          currentQuarter = maxQuarter;
          stopQuarterTimer();
        }
      });
    });
  }

  void endMatch() {
    setState(() {
      matchStarted = false;
      judgingQuarter = maxQuarter + 1;
    });
    stopQuarterTimer();
  }

  void loadPlayersFor(String team) async {
    final snapshot = await db.collection('players').where('team_belong', isEqualTo: team).get();
    setState(() {
      players = snapshot.docs.map((doc) => doc['name'] as String).toList();
      selectedPlayer = players.isNotEmpty ? players.first : null;
    });
  }

  void insertAction(String actionType) {
    if (selectedTeam == null || selectedPlayer == null) {
      showAlert("Select valid team and player.");
      return;
    }

    final data = {
      'player': selectedPlayer,
      'team': selectedTeam,
      'quarter': "$currentQuarter",
      'actionType': actionType,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toDouble()
    };

    db.collection("matches")
        .doc(widget.matchID)
        .collection("history_actions")
        .add(data)
        .then((_) => showAlert("Action $actionType recorded"))
        .catchError((error) => showAlert("Error: $error"));
         Provider.of<MatchModel>(context,listen:false).loadMatchesFromFirestore();
  }

  void showAlert(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    quarterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Action")),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Text("Select Your Team: ",style: TextStyle(fontSize: 20)),
            DropdownButton<String>(
              value: selectedTeam,
              onChanged: (val) {
                setState(() {
                  selectedTeam = val;
                  loadPlayersFor(val!);
                });
              },
              items: teams.map((team) => DropdownMenuItem(value: team, child: Text(team))).toList(),
            ),
            SizedBox(height:60),
            const Text("Select Your Players: ",style: TextStyle(fontSize: 20)),
            DropdownButton<String>(
              value: selectedPlayer,
              onChanged: (val) => setState(() => selectedPlayer = val),
              items: players.map((player) => DropdownMenuItem(value: player, child: Text(player))).toList(),
            ),
            SizedBox(height:60),
            Text("Choose start match or end match: ",style: TextStyle(fontSize: 20)),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(onPressed: matchStarted ? null : startMatch, child: Text("Start Match")),
                SizedBox(width:60),
                ElevatedButton(onPressed: !matchStarted ? null : endMatch, child: Text("End Match")),
              ],
            ),
            SizedBox(height:60),
            Container(
              width: double.infinity,
              child: Text(
                "Quarter: $currentQuarter",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height:20),
            Text("Choose your action type: ",style: TextStyle(fontSize: 20)),
            Wrap(
              spacing: 20, // spacing between buttons
              runSpacing: 10, // spacing between lines
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(onPressed: () => handleBaseAction("Kick"), child: Text("Kick")),
                ElevatedButton(onPressed: () => handleBaseAction("Handball"), child: Text("Handball")),
                ElevatedButton(onPressed: () => insertAction("Mark (Catching the ball)"), child: Text("Mark")),
                ElevatedButton(onPressed: () => insertAction("Tackle"), child: Text("Tackle")),
              ],
            ),
            SizedBox(height:20),
            Text("Choose your score type: ",style: TextStyle(fontSize: 20)),
            if (awaitingScoringOption)
              Wrap(
                spacing: 10,
                children: [
                  if (lastBaseAction == "Kick")
                    ElevatedButton(onPressed: () => handleScoring("Kick Goal Scored (6 Points)"), child: Text("Goal")),
                  ElevatedButton(
                      onPressed: () => handleScoring(
                          lastBaseAction == "Kick"
                              ? "Kick Behind Scored (1 Point)"
                              : "Handball Behind Score (1 Point)"),
                      child: Text("Behind")),
                  ElevatedButton(
                      onPressed: () => handleScoring(
                          lastBaseAction == "Kick"
                              ? "Kick No Score (0 Points)"
                              : "Handball No Score (0 Points)"),
                      child: Text("No Score")),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void handleBaseAction(String action) {
    if (!matchStarted || judgingQuarter > maxQuarter) {
      showAlert("The match has ended.");
      return;
    }
    setState(() {
      lastBaseAction = action;
      lastActionTeam = selectedTeam;
      awaitingScoringOption = true;
    });
  }

  void handleScoring(String actionType) {
    if (lastBaseAction == "Kick" && actionType.contains("Goal") && selectedTeam != lastActionTeam) {
      showAlert("Goal must be by the same team who kicked.");
      return;
    }
    insertAction(actionType);
    setState(() {
      awaitingScoringOption = false;
      lastBaseAction = null;
    });
  }
}
