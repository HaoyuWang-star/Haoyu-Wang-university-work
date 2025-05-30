import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'match.dart';
import 'create_match.dart';
import 'match_details.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("\n\nConnected to Firebase App ${app.options.projectId}\n\n");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MatchModel(),
      child: MaterialApp(
        title: 'Match List',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const MatchListPage(),
      ),
    );
  }
}

class MatchListPage extends StatelessWidget {
  const MatchListPage({Key? key}) : super(key: key);

  int extractTotalScore(String? score) {
    if (score == null || score.isEmpty) return 0;
    final match = RegExp(r'\((\d+)\)').firstMatch(score);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchModel>(
      builder: (context, matchModel, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Matches")),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateMatchPage()),
              );
            },
            child: const Icon(Icons.add),
          ),
          body: matchModel.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: matchModel.matches.length,
            itemBuilder: (context, index) {
              final match = matchModel.matches[index];
              final score1 = match.score1?.isNotEmpty == true ? match.score1! : "0.0 (0)";
              final score2 = match.score2?.isNotEmpty == true ? match.score2! : "0.0 (0)";
              final total1 = extractTotalScore(score1);
              final total2 = extractTotalScore(score2);

              return Dismissible(
                key: Key(match.id ?? index.toString()), // Ensure match.id is not null or fallback
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
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text('Are you sure you want to delete this match?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await matchModel.deleteMatch(match);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Match deleted')),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MatchDetailPage(match: match)),
                    );
                  },
                  child: MatchCard(match: match, total1: total1, total2: total2),
                ),
              );
            },
          )

        );
      },
    );
  }
}
class MatchCard extends StatelessWidget {
  final Match match;
  final int total1;
  final int total2;

  const MatchCard({
    Key? key,
    required this.match,
    required this.total1,
    required this.total2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final score1 = match.score1?.isNotEmpty == true ? match.score1! : "0.0 (0)";
    final score2 = match.score2?.isNotEmpty == true ? match.score2! : "0.0 (0)";

    final boldStyle = const TextStyle(fontWeight: FontWeight.bold, color: Colors.red);
    final normalStyle = const TextStyle(color: Colors.black);

    final team1Style = total1 > total2 ? boldStyle : normalStyle;
    final team2Style = total2 > total1 ? boldStyle : normalStyle;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            match.imageBase64.isNotEmpty
                ? Image.memory(
              match.imageBytes(),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 100);
              },
            )
                : const Icon(Icons.image, size: 100),
            const SizedBox(height: 8),

            // Date & Location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Date: ${match.date ?? 'N/A'}"),
                Text("Location: ${match.location ?? 'N/A'}"),
              ],
            ),
            const SizedBox(height: 12),

            // Team names with VS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    match.team1 ?? 'Team 1',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "VS",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.team2 ?? 'Team 2',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Team scores
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    score1,
                    textAlign: TextAlign.center,
                    style: team1Style,
                  ),
                ),
                Expanded(
                  child: Text(
                    score2,
                    textAlign: TextAlign.center,
                    style: team2Style,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


