import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WormGraphPage extends StatefulWidget {
  final String matchID;
  final String team1Name;
  final String team2Name;

  const WormGraphPage({
    Key? key,
    required this.matchID,
    required this.team1Name,
    required this.team2Name,
  }) : super(key: key);

  @override
  _WormGraphPageState createState() => _WormGraphPageState();
}

class _WormGraphPageState extends State<WormGraphPage> {
  List<FlSpot> marginSpots = [];
  List<ScoreSnapshot> scoresByIndex = [];

  @override
  void initState() {
    super.initState();
    fetchAndDisplayGraph();
  }

  Future<void> fetchAndDisplayGraph() async {
    final db = FirebaseFirestore.instance;
    final actionsRef = db
        .collection('matches')
        .doc(widget.matchID)
        .collection('history_actions');

    final snapshot = await actionsRef.orderBy('timestamp').get();

    int team1Score = 0;
    int team2Score = 0;
    int index = 0;

    List<FlSpot> spots = [];
    List<ScoreSnapshot> snapshots = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final team = data['team'] as String? ?? '';
      final actionType = data['actionType'] as String? ?? '';

      if (team == widget.team1Name) {
        if (actionType.contains('6 Points')) {
          team1Score += 6;
        } else if (actionType.contains('1 Point')) {
          team1Score += 1;
        }
      } else if (team == widget.team2Name) {
        if (actionType.contains('6 Points')) {
          team2Score += 6;
        } else if (actionType.contains('1 Point')) {
          team2Score += 1;
        }
      }

      final margin = team1Score - team2Score;
      spots.add(FlSpot(index.toDouble(), margin.toDouble()));
      snapshots.add(ScoreSnapshot(team1Score, team2Score));
      index++;
    }

    setState(() {
      marginSpots = spots;
      scoresByIndex = snapshots;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.team1Name} vs ${widget.team2Name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: marginSpots.isEmpty
            ? const Center(child: CircularProgressIndicator())
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Worm Graph Explanation:\n'
                '• Y-axis = Score Margin (${widget.team1Name} - ${widget.team2Name})\n'
                '• Line goes ↑ when ${widget.team1Name} get scores\n'
                '• Line goes ↓ when ${widget.team2Name} get scores\n',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 12),
          Expanded(
              child:LineChart(
              LineChartData(
            extraLinesData: ExtraLinesData(
              verticalLines: [
                VerticalLine(x: (marginSpots.length / 4).roundToDouble(), color: Colors.grey, strokeWidth: 1, dashArray: [4, 4]),
                VerticalLine(x: (marginSpots.length / 2).roundToDouble(), color: Colors.grey, strokeWidth: 1, dashArray: [4, 4]),
                VerticalLine(x: (marginSpots.length * 3 / 4).roundToDouble(), color: Colors.grey, strokeWidth: 1, dashArray: [4, 4]),
              ],
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.blueAccent,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    if (index >= scoresByIndex.length) return null;

                    final snapshot = scoresByIndex[index];
                    return LineTooltipItem(
                      '${widget.team1Name}: ${snapshot.team1Score}\n'
                          '${widget.team2Name}: ${snapshot.team2Score}\n'
                          'Margin: ${snapshot.team1Score - snapshot.team2Score}',
                      const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier', // or 'monospace'
                        fontSize: 14,
                      ),
                    );

                  }).whereType<LineTooltipItem>().toList();
                },
              ),
            ),
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 1, // Always ask for every index
                    getTitlesWidget: (value, meta) {
                      final total = marginSpots.length;
                      if (total < 4) return const SizedBox.shrink();

                      final q1Index = 0;
                      final q2Index = (total / 4).round();
                      final q3Index = (total / 2).round();
                      final q4Index = (3 * total / 4).round();

                      if (value.toInt() == q1Index) return const Text('Q1');
                      if (value.toInt() == q2Index) return const Text('Q2');
                      if (value.toInt() == q3Index) return const Text('Q3');
                      if (value.toInt() == q4Index) return const Text('Q4');

                      return const Text('');
                    }

                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(),
                bottom: BorderSide(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: marginSpots,
                isCurved: true,
                barWidth: 3,
                color: Colors.blue,
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
   ],
    ),
    )
    );
  }
}

class ScoreSnapshot {
  final int team1Score;
  final int team2Score;

  ScoreSnapshot(this.team1Score, this.team2Score);
}
