import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'PlayerStats.dart';


class ContributionPage extends StatefulWidget {
  final String matchID;
  final String teamName;

  const ContributionPage({super.key, required this.matchID, required this.teamName});

  @override
  State<ContributionPage> createState() => _ContributionPageState();
}

class _ContributionPageState extends State<ContributionPage> {
  List<PlayerStats> playerStatsList = [];

  @override
  void initState() {
    super.initState();
    fetchPlayerContributions();
  }

  Future<void> fetchPlayerContributions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchID)
        .collection('history_actions')
        .where('team', isEqualTo: widget.teamName)
        .get();

    final Map<String, PlayerStats> statsMap = {};

    for (var doc in snapshot.docs) {
      final player = doc['player'];
      final actionType = doc['actionType'];

      final stats = statsMap[player] ?? PlayerStats(playerName: player);

      switch (actionType) {
        case 'Kick Goal Scored (6 Points)':
          stats.totalKickGoals++;
          break;
        case 'Kick Behind Scored (1 Point)':
          stats.totalKickBehinds++;
          break;
        case 'Kick No Score(0 Points)':
          stats.totalKickNoScore++;
          break;
        case 'Mark (catching the ball)':
          stats.totalMarks++;
          break;
        case 'Tackle':
          stats.totalTackles++;
          break;
        case 'Handball Behind Score (1 Point)':
          stats.totalHandballBehinds++;
          break;
        case 'Handball No Score (0 Points)':
          stats.totalHandballNoScore++;
          break;
      }

      statsMap[player] = stats;
    }

    setState(() {
      playerStatsList = statsMap.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final int teamTotalScore =
    playerStatsList.fold(0, (sum, p) => sum + p.totalScore);

    return Scaffold(
      appBar: AppBar(title: const Text('Player Contributions')),
      body: ListView.builder(
        itemCount: playerStatsList.length,
        itemBuilder: (context, index) {
          final stats = playerStatsList[index];
          final percent = teamTotalScore > 0
              ? (stats.totalScore / teamTotalScore) * 100
              : 0;

          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stats.playerName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Total Score: ${stats.totalScore}'),
                  Text('Percent: ${percent.toStringAsFixed(1)}%'),
                  Text('Kicks: ${stats.totalKicks}'),
                  Text('Handballs: ${stats.totalHandballs}'),
                  Text('Goals: ${stats.totalKickGoals}'),
                  Text('Behinds: ${stats.totalBehinds}'),
                  Text('Marks: ${stats.totalMarks}'),
                  Text('Tackles: ${stats.totalTackles}'),
                  const SizedBox(height: 12),
                  SizedBox(height: 150, child: _buildPieChart(percent.toDouble())),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPieChart(double percent) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: percent,
            color: Colors.green,
            title: '${percent.toStringAsFixed(0)}%',
            radius: 40,
            titleStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: 100 - percent,
            color: Colors.grey.shade300,
            title: '',
            radius: 40,
          ),
        ],
        centerSpaceRadius: 20,
        sectionsSpace: 0,
      ),
    );
  }
}
