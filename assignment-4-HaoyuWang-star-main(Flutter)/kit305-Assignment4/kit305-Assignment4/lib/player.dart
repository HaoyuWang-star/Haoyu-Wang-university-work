import 'dart:convert';
import 'dart:typed_data';

class Player {
  String? playerId;
  String name;
  int? age;
  String teamBelong;
  String? imageBase64;

  Uint8List imageBytes() {
    try {
      if (imageBase64 == null || imageBase64!.trim().isEmpty) return Uint8List(0);

      final regex = RegExp(r'data:image/[^;]+;base64,');
      final cleanedBase64 = imageBase64!.replaceAll(regex, '').trim();
      final normalized = base64.normalize(cleanedBase64);

      return base64Decode(normalized);
    } catch (e) {
      print("Base64 decoding error for player $playerId: $e");
      return Uint8List(0);
    }
  }

  Player({
    this.playerId,
    required this.name,
    this.age,
    required this.teamBelong,
    this.imageBase64,
  });

  factory Player.fromMap(Map<String, dynamic> data, String id) {
    return Player(
      playerId: id,
      name: data['name'] ?? '',
      age: data['age'],
      teamBelong: data['team_belong'] ?? '',
      imageBase64: data['imageBase64'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'name': name,
      'age': age,
      'team_belong': teamBelong,
      'imageBase64': imageBase64,
    };
  }

  Player copyWith({
    String? playerId,
    String? name,
    int? age,
    String? teamBelong,
    String? imageBase64,
  }) {
    return Player(
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      age: age ?? this.age,
      teamBelong: teamBelong ?? this.teamBelong,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}


