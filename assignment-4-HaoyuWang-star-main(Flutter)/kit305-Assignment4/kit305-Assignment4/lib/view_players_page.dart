import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'contribution_page.dart';
import 'create_player_page.dart';
import 'edit_player_page.dart';
import 'player.dart';
import 'player_tile.dart';


class ViewPlayersPage extends StatefulWidget {
  final String teamName;
  final String matchID;

  const ViewPlayersPage({
    Key? key,
    required this.teamName,
    required this.matchID,
  }) : super(key: key);

  @override
  _ViewPlayersPageState createState() => _ViewPlayersPageState();
}

class _ViewPlayersPageState extends State<ViewPlayersPage> {
  List<Player> allPlayers = [];
  List<Player> filteredPlayers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadPlayers();
  }

  void loadPlayers() async {
    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('players')
        .where('team_belong', isEqualTo: widget.teamName)
        .get();

    final players = snapshot.docs.map((doc) {
      return Player.fromMap(doc.data(), doc.id);
    }).toList();

    setState(() {
      allPlayers = players;
      filteredPlayers = players;
      isLoading = false;
    });
  }

  void filterPlayers(String query) {
    setState(() {
      searchQuery = query;
      filteredPlayers = query.isEmpty
          ? allPlayers
          : allPlayers.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void deletePlayer(Player player) async {
    await FirebaseFirestore.instance.collection('players').doc(player.playerId).delete();

    setState(() {
      allPlayers.removeWhere((p) => p.playerId == player.playerId);
      filteredPlayers.removeWhere((p) => p.playerId == player.playerId);
    });
  }

  void updatePlayer(Player updatedPlayer) {
    final index = filteredPlayers.indexWhere((p) => p.playerId == updatedPlayer.playerId);
    if (index != -1) {
      setState(() {
        filteredPlayers[index] = updatedPlayer;
        final allIndex = allPlayers.indexWhere((p) => p.playerId == updatedPlayer.playerId);
        allPlayers[allIndex] = updatedPlayer;
      });
    }
  }

  Future<void> addNewPlayer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePlayerPage(teamName: widget.teamName),
      ),
    );

    if (result == true) {
      //Reload player list from Firestore
      loadPlayers();
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.teamName} Players'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              onChanged: filterPlayers,
              decoration: const InputDecoration(
                hintText: 'Search players',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNewPlayer,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredPlayers.isEmpty
          ? const Center(
        child: Text(
          'No players found.\nTry adding or changing your search.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : Column(
        children: [
          if (allPlayers.length < 2)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Less than two players, please add more players for the match.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPlayers.length,
              itemBuilder: (context, index) {
                final player = filteredPlayers[index];
                return Dismissible(
                  key: Key(player.playerId!),
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
                        title: Text("Delete ${player.name}?"),
                        content: const Text("Are you sure you want to delete this player?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    deletePlayer(player);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${player.name} deleted')),
                    );
                  },
                  child: PlayerTile(
                    player: player,
                    onEdit: () async {
                      final updated = await Navigator.push<Player>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPlayerPage(player: player),
                        ),
                      );
                      if (updated != null) updatePlayer(updated);
                    },
                  ),
                );
              },
            ),
          ),


        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            // Uncomment this once ContributionPage is implemented:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContributionPage(
                  teamName: widget.teamName,
                  matchID: widget.matchID,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("View Players' Contribution", style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

