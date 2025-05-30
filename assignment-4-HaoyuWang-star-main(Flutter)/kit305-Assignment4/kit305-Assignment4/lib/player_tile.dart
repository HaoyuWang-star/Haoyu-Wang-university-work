import 'dart:convert';
import 'package:flutter/material.dart';
import 'player.dart';

class PlayerTile extends StatelessWidget {
  final Player player;
  final VoidCallback? onEdit;


  const PlayerTile({
    Key? key,
    required this.player,
    required this.onEdit,

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (player.imageBase64 != null && player.imageBase64!.isNotEmpty) {
      image = MemoryImage(base64Decode(player.imageBase64!));
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: image,
        backgroundColor: Colors.grey[300],
      ),
      title: Text(player.name),
      subtitle: Text('Age: ${player.age}'),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: onEdit,
      ),
    );
  }
}
