import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';  // Import Firebase core

class AdvertisingPanelPage extends StatefulWidget {
  @override
  _AdvertisingPanelPageState createState() => _AdvertisingPanelPageState();
}

class _AdvertisingPanelPageState extends State<AdvertisingPanelPage> {
  final List<String?> _imageUrls = List<String?>.filled(5, null);
  final List<TextEditingController> _linkControllers =
      List.generate(5, (_) => TextEditingController());
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Upload the image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('ads/${pickedFile.name}_${DateTime.now()}');
      await storageRef.putFile(File(pickedFile.path));
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _imageUrls[index] = downloadUrl; // Store the image URL
      });
    }
  }

  Future<void> _saveData() async {
    List<Map<String, dynamic>> adData = [];

    for (int i = 0; i < 5; i++) {
      if (_imageUrls[i] != null && _linkControllers[i].text.isNotEmpty) {
        adData.add({
          'imageUrl': _imageUrls[i],
          'link': _linkControllers[i].text,
        });
      }
    }

    // Save adData to Firestore
    await FirebaseFirestore.instance
        .collection('adsPanel')
        .doc('advertisements')
        .set({'ads': adData});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data saved successfully!")),
    );
  }

  @override
  void dispose() {
    for (var controller in _linkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Advertising Panel"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Import 5 images or videos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickImage(index),
                          child: Container(
                            height: 100,
                            margin: EdgeInsets.only(top: 10, right: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: _imageUrls[index] == null
                                ? Icon(Icons.add, color: Colors.grey)
                                : Image.network(_imageUrls[index]!,
                                    fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _linkControllers[index],
                          decoration: InputDecoration(
                            hintText: "Add your link here",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveData,
                child: Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
