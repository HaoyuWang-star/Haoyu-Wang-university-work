import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class PlayerComparePage extends StatefulWidget {
  final String matchID;
  final String team1Name;
  final String team2Name;

  const PlayerComparePage({
    Key? key,
    required this.matchID,
    required this.team1Name,
    required this.team2Name,
  }) : super(key: key);

  @override
  _PlayerComparePageState createState() => _PlayerComparePageState();
}

class _PlayerComparePageState extends State<PlayerComparePage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  List<String> playersTeam1 = [];
  List<String> playersTeam2 = [];

  String? selectedPlayer1;
  String? selectedPlayer2;

  Map<String, double>? leftStats;
  Map<String, double>? rightStats;

  @override
  void initState() {
    super.initState();
    fetchPlayers(widget.team1Name, isLeft: true);
    fetchPlayers(widget.team2Name, isLeft: false);
  }

  Future<void> fetchPlayers(String team, {required bool isLeft}) async {
    final snapshot = await db
        .collection('players')
        .where('team_belong', isEqualTo: team)
        .get();

    final names = snapshot.docs
        .map((doc) => doc.data()['name'] as String)
        .toList();

    setState(() {
      if (isLeft) {
        playersTeam1 = names;
      } else {
        playersTeam2 = names;
      }
    });
  }

  Future<void> fetchPlayerStats(String playerName, {required bool isLeft}) async {
    final snapshot = await db
        .collection('matches')
        .doc(widget.matchID)
        .collection('history_actions')
        .where('player', isEqualTo: playerName)
        .get();

    int kickGoals = 0;
    int handballBehinds = 0;
    int score = 0;

    for (var doc in snapshot.docs) {
      final type = doc.data()['actionType'] as String? ?? '';
      switch (type) {
        case 'Kick Goal Scored (6 Points)':
          kickGoals += 1;
          score += 6;
          break;
        case 'Handball Behind Score (1 Point)':
          handballBehinds += 1;
          score += 1;
          break;
        default:
          break;
      }
    }

    final stats = {
      'Kick': kickGoals.toDouble(),
      'Handball': handballBehinds.toDouble(),
      'Score': score.toDouble(),
    };

    setState(() {
      if (isLeft) {
        leftStats = stats;
      } else {
        rightStats = stats;
      }
    });
  }

  Widget buildDropdown({
    required List<String> items,
    required String? selectedItem,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return DropdownButton<String>(
      value: selectedItem,
      hint: Text(hint),
      items: items.map((name) {
        return DropdownMenuItem(
          value: name,
          child: Text(name),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  void updateChart() {
    if (selectedPlayer1 != null &&
        selectedPlayer2 != null &&
        selectedPlayer1 == selectedPlayer2) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Invalid Selection'),
          content: Text("You can't select the same player for both sides."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (selectedPlayer1 != null) {
      fetchPlayerStats(selectedPlayer1!, isLeft: true);
    }
    if (selectedPlayer2 != null) {
      fetchPlayerStats(selectedPlayer2!, isLeft: false);
    }
  }

  BarChartGroupData makeGroupData(int x, double leftY, double rightY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: leftY,
          color: Colors.blue,
          width: 8,
        ),
        BarChartRodData(
          toY: rightY,
          color: Colors.green,
          width: 8,
        ),
      ],
    );
  }

  Widget buildBarChart() {
    if (leftStats == null || rightStats == null) {
      return Center(child: Text('Select players to compare stats.'));
    }

    final barGroups = [
      makeGroupData(0, leftStats!['Kick'] ?? 0, rightStats!['Kick'] ?? 0),
      makeGroupData(1, leftStats!['Handball'] ?? 0, rightStats!['Handball'] ?? 0),
      makeGroupData(2, leftStats!['Score'] ?? 0, rightStats!['Score'] ?? 0),
    ];

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['Kick', 'Handball', 'Score'];
                return Text(labels[value.toInt()]);
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Comparison'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Player selectors
            Row(
              children: [
                Expanded(
                  child: buildDropdown(
                    items: playersTeam1,
                    selectedItem: selectedPlayer1,
                    onChanged: (value) {
                      setState(() {
                        selectedPlayer1 = value;
                      });
                      updateChart();
                    },
                    hint: 'Select Player From ${widget.team1Name}',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: buildDropdown(
                    items: playersTeam2,
                    selectedItem: selectedPlayer2,
                    onChanged: (value) {
                      setState(() {
                        selectedPlayer2 = value;
                      });
                      updateChart();
                    },
                    hint: 'Select Player From ${widget.team2Name}',
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Legend for bar colors
            if (selectedPlayer1 != null || selectedPlayer2 != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedPlayer1 != null)
                    Row(
                      children: [
                        Container(width: 16, height: 16, color: Colors.blue),
                        SizedBox(width: 6),
                        Text(selectedPlayer1!),
                      ],
                    ),
                  if (selectedPlayer1 != null && selectedPlayer2 != null)
                    SizedBox(width: 24),
                  if (selectedPlayer2 != null)
                    Row(
                      children: [
                        Container(width: 16, height: 16, color: Colors.green),
                        SizedBox(width: 6),
                        Text(selectedPlayer2!),
                      ],
                    ),
                ],
              ),

            SizedBox(height: 24),

            // Chart
            Expanded(
              child: buildBarChart(),
            ),
          ],
        ),
      ),
    );
  }
}
