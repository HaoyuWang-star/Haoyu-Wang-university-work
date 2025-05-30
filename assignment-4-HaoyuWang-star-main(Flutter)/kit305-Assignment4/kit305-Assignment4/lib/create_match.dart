import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'match.dart';

class CreateMatchPage extends StatefulWidget {
  @override
  _CreateMatchPageState createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  final TextEditingController team1Controller = TextEditingController();
  final TextEditingController team2Controller = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  Uint8List? _imageBytes;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (bytes.length < 1000000) {
        setState(() {
          _imageBytes = bytes;
        });
      } else {
        _showAlert('Image Too Large', 'Please select a smaller image.');
      }
    }
  }

  void _saveMatch() async {
    final team1 = team1Controller.text.trim();
    final team2 = team2Controller.text.trim();
    final date = dateController.text.trim();
    final location = locationController.text.trim();

    if (team1.isEmpty || team2.isEmpty || date.isEmpty || location.isEmpty) {
      _showAlert('Missing Fields', 'Please fill all fields.');
      return;
    }

    if (team1.toLowerCase() == team2.toLowerCase()) {
      _showAlert('Invalid Teams', 'Team 1 and Team 2 must be different.');
      return;
    }

    Map<String, dynamic> matchData = {
      'team1': team1,
      'team2': team2,
      'date': date,
      'location': location,
      'startTimestamp': 0,
    };

    if (_imageBytes != null) {
      matchData['imageBase64'] = base64Encode(_imageBytes!);
    }
    await FirebaseFirestore.instance.collection('matches').add(matchData);
    Provider.of<MatchModel>(context,listen:false).loadMatchesFromFirestore();
    Navigator.pop(context);
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Match')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _imageBytes == null
                    ? Center(child: Text('Tap to select image'))
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 150,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(controller: team1Controller, decoration: InputDecoration(labelText: 'Team 1')),
            TextField(controller: team2Controller, decoration: InputDecoration(labelText: 'Team 2')),
            TextField(controller: dateController, decoration: InputDecoration(labelText: 'Date')),
            TextField(controller: locationController, decoration: InputDecoration(labelText: 'Location')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveMatch,
              child: Text('Save Match'),
            ),
          ],
        ),
      ),
    );
  }
}
