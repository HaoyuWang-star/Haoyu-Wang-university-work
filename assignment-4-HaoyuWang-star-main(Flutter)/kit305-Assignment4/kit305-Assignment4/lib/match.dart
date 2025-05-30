import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  String id;
  String? matchId;
  String? team1;
  String? team2;
  String? score1;
  String? score2;
  String? date;
  String? location;
  int startTimestamp;
  String imageBase64;


  Match({
    required this.id,
    this.matchId,
    this.team1,
    this.team2,
    this.score1,
    this.score2,
    this.date,
    this.location,
    this.startTimestamp = 0,
    this.imageBase64 = '',
  });

  Uint8List imageBytes() {
    try {
      if (imageBase64.trim().isEmpty) return Uint8List(0);

      // Safely strip any data URI header
      final regex = RegExp(r'data:image/[^;]+;base64,');
      final cleanedBase64 = imageBase64.replaceAll(regex, '').trim();

      // Ensure padding is correct
      final normalized = base64.normalize(cleanedBase64);

      return base64Decode(normalized);
    } catch (e) {
      print("Base64 decoding error for match $matchId: $e");
      return Uint8List(0);
    }
  }
  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Match(
      id: doc.id,
      team1: data['team1'],
      team2: data['team2'],
      location: data['location'],
      date: data['date'],
      score1: data['score1'],
      score2: data['score2'],
      imageBase64: data['imageBase64'] ?? '',
    );
  }
  Match.fromJson(Map<String, dynamic> json, this.id)
      :
        team1 = json['team1'],
        team2 = json['team2'],
        score1 = json['score1'],
        score2 = json['score2'],
        date = json['date'],
        location = json['location'],
        startTimestamp = json['startTimestamp'] ?? 0,
        imageBase64 = json['imageBase64'] ?? '';

  Map<String, dynamic> toJson() => {
    'team1': team1,
    'team2': team2,
    'score1': score1,
    'score2': score2,
    'date': date,
    'location': location,
    'startTimestamp': startTimestamp,
    'imageBase64': imageBase64,
  };
  Future<void> calculateScores() async {
    final db = FirebaseFirestore.instance;
    final historySnapshot = await db
        .collection('matches')
        .doc(id)
        .collection('history_actions')
        .get();

    int team1Goals = 0;
    int team1Behinds = 0;
    int team2Goals = 0;
    int team2Behinds = 0;

    for (var doc in historySnapshot.docs) {
      final data = doc.data();
      final actionType = data['actionType'];
      final team = data['team'];

      if (actionType == "Kick Goal Scored (6 Points)") {
        if (team == team1) {
          team1Goals++;
        } else if (team == team2) {
          team2Goals++;
        }
      } else if (actionType == "Kick Behind Scored (1 Point)" || actionType == "Handball Behind Score (1 Point)") {
        if (team == team1) {
          team1Behinds++;
        } else if (team == team2) {
          team2Behinds++;
        }
      }
    }

    int total1 = (team1Goals * 6) + team1Behinds;
    int total2 = (team2Goals * 6) + team2Behinds;

    score1 = "$team1Goals.$team1Behinds ($total1)";
    score2 = "$team2Goals.$team2Behinds ($total2)";
  }

}

class MatchModel extends ChangeNotifier {
  final List<Match> _matches = [];
  final CollectionReference matchesCollection = FirebaseFirestore.instance.collection('matches');

  bool _loading = false;

  List<Match> get matches => _matches;
  bool get loading => _loading;

  MatchModel() {
    loadMatchesFromFirestore();
  }

  Future<void> loadMatchesFromFirestore() async {
    _loading = true;
    notifyListeners();

    final snapshot = await matchesCollection.orderBy("date").get();
    _matches.clear();

    for (var doc in snapshot.docs) {
      final match = Match.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
      await match.calculateScores(); // Calculate score based on actions
      _matches.add(match);
    }

    _loading = false;
    notifyListeners();
  }


  Match? get(String? id) {
    if (id == null) return null;
    return _matches.firstWhere((match) => match.id == id, orElse: () => null as Match);
  }

  Future add(Match item) async {
    _loading = true;
    notifyListeners();

    await matchesCollection.add(item.toJson());
    await loadMatchesFromFirestore();
  }

  Future updateItem(String id, Match item) async {
    _loading = true;
    notifyListeners();

    await matchesCollection.doc(id).set(item.toJson());
    await loadMatchesFromFirestore();
  }

  Future<void> deleteMatch(Match match) async {
    try {
      if (match.id != null) {
        await FirebaseFirestore.instance.collection('matches').doc(match.id).delete();
        matches.removeWhere((m) => m.id == match.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error deleting match: $e");
    }
  }

}
