import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'match.dart';

class MatchHistoryPage extends StatefulWidget {
  final String matchID;
  final String team1Name;
  final String team2Name;

  const MatchHistoryPage({
    super.key,
    required this.matchID,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  State<MatchHistoryPage> createState() => _MatchHistoryPageState();
}

class _MatchHistoryPageState extends State<MatchHistoryPage> {
  List<ActionModel> actions = [];

  @override
  void initState() {
    super.initState();
    loadMatchHistory();
  }

  void loadMatchHistory() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchID)
          .collection('history_actions')
          .orderBy('timestamp')
          .get();

      setState(() {
        actions = snapshot.docs
            .map((doc) => ActionModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      print('Error loading actions: $e');
    }
  }

  void shareMatchHistory() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchID)
          .collection('history_actions')
          .orderBy('timestamp')
          .get();

      final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      String finalText = '';

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final player = data['player'] ?? 'Unknown Player';
        final actionType = data['actionType'] ?? 'Unknown Action';
        final timestamp = (data['timestamp'] ?? 0).toDouble();
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
        final formattedDate = formatter.format(date);

        finalText += '[$formattedDate] $player - $actionType\n';
      }

      if (context.mounted) {
        if (finalText.isEmpty) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('No Actions'),
              content: const Text('No actions to share.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          await Share.share(finalText);
        }
      }
    } catch (e) {
      print('Error sharing match history: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          shareMatchHistory();
        },
        child: const Icon(Icons.share),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('${actions.length} Actions found'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                final date = DateTime.fromMillisecondsSinceEpoch(action.timestamp.toInt());
                final timeStr = DateFormat('HH:mm:ss').format(date);

                return Dismissible(
                  key: Key(action.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Confirm deletion"),
                        content: Text("Are you sure you want to delete the action record for ${action.player}?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('matches')
                          .doc(widget.matchID)
                          .collection('history_actions')
                          .doc(action.id)
                          .delete();
                      Provider.of<MatchModel>(context,listen:false).loadMatchesFromFirestore();
                      setState(() {
                        actions.removeAt(index);
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Record deleted")),
                      );
                    } catch (e) {
                      print("Failed to delete: $e");
                    }
                  },
                  child: ListTile(
                    title: Text('${action.player} (${action.team}) - ${action.actionType}'),
                    subtitle: Text('Quarter ${action.quarter} | $timeStr'),
                  ),
                );

              },
            ),
          ),
        ],
      ),
    );
  }
}

class ActionModel {
  final String id; // 新增 ID 字段
  final String player;
  final String team;
  final String actionType;
  final String quarter;
  final double timestamp;

  ActionModel({
    required this.id,
    required this.player,
    required this.team,
    required this.actionType,
    required this.quarter,
    required this.timestamp,
  });

  factory ActionModel.fromMap(Map<String, dynamic> data, String id) {
    return ActionModel(
      id: id,
      player: data['player'] ?? '',
      team: data['team'] ?? '',
      actionType: data['actionType'] ?? '',
      quarter: data['quarter'] ?? '',
      timestamp: (data['timestamp'] ?? 0).toDouble(),
    );
  }
}
