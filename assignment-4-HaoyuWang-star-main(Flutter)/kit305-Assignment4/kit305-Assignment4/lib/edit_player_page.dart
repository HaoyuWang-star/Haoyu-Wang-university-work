import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'player.dart';

class EditPlayerPage extends StatefulWidget {
  final Player player;

  const EditPlayerPage({Key? key, required this.player}) : super(key: key);

  @override
  State<EditPlayerPage> createState() => _EditPlayerPageState();
}

class _EditPlayerPageState extends State<EditPlayerPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.player.name;
    _ageController.text = widget.player.age?.toString() ?? '';

    if (widget.player.imageBase64 != null && widget.player.imageBase64!.isNotEmpty) {
      _imageBytes = base64Decode(widget.player.imageBase64!);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());

    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid age")),
      );
      return;
    }

    final updatedData = {
      'name': name,
      'age': age,
    };

    if (_imageBytes != null) {
      updatedData['imageBase64'] = base64Encode(_imageBytes!);
    }

    try {
      await FirebaseFirestore.instance
          .collection('players')
          .doc(widget.player.playerId)
          .update(updatedData);

      final updatedPlayer = widget.player.copyWith(
        name: name,
        age: age,
        imageBase64: (updatedData['imageBase64'] ?? widget.player.imageBase64) as String?,

      );

      if (context.mounted) {
        Navigator.pop(context, updatedPlayer);
      }
    } catch (e) {
      print('Failed to update player: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update player")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Player')),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Update Player'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
