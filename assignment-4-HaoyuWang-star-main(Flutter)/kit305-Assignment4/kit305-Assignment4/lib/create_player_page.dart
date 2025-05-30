import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreatePlayerPage extends StatefulWidget {
  final String teamName;

  const CreatePlayerPage({super.key, required this.teamName});

  @override
  State<CreatePlayerPage> createState() => _CreatePlayerPageState();
}

class _CreatePlayerPageState extends State<CreatePlayerPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (bytes.length < 1000000) {
        setState(() {
          _imageBytes = bytes;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image too large. Please select a smaller one.")),
        );
      }
    }
  }

  Future<void> _savePlayer() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;

    final playerData = {
      'name': name,
      'age': age,
      'team_belong': widget.teamName,
      'kick': 0,
      'handball': 0,
      'tackle': 0,
      'mark': 0,
      'goalScore': 0,
      'behindScore': 0,
    };

    if (_imageBytes != null) {
      playerData['imageBase64'] = base64Encode(_imageBytes!);
    }

    try {
      await FirebaseFirestore.instance.collection('players').add(playerData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Player saved successfully")),
      );

      Navigator.pop(context, true); // This tells the previous screen to refresh
    } catch (e) {
      if (!mounted) return;

      print('Error saving player: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save player")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Player')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _imageBytes != null
                        ? ClipOval(
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.cover,
                        height: 120,
                        width: 120,
                      ),
                    )
                        : const Icon(Icons.person, size: 60),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _pickImage, child: const Text('Select Image')),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Enter age' : null,
              ),
              const SizedBox(height: 10),
              Text('Team: ${widget.teamName}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePlayer,
                child: const Text('Save Player'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

