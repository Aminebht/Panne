import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:panne_auto/pages/artisan_page/request_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:panne_auto/providers/auth_providers.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;


class FreeTrialPage extends StatelessWidget {
  final String DropdownValue;
  final TextEditingController _descriptionController = TextEditingController();

  FreeTrialPage({required this.DropdownValue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(35, 90, 129, 1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Image at the top
              SizedBox(height: 80),
              Image.asset(
                'assets/icons/free_trial.png', // Replace with your image path
                height: 248,
              ),
              SizedBox(height: 100),
              // Text message
              Text(
                AppLocalizations.of(context)!.freetrial,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 80),
              // Call-to-action button
              ElevatedButton(
                onPressed: () async {
                  await addJob(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => RequestPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(226, 145, 0, 1), // Button color
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                   alignment: Alignment.center,
                ),
                child:Center(
                child: Text(
                  AppLocalizations.of(context)!.trialbutton,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> addJob(BuildContext context) async {
  final ref = ProviderContainer();
  try {
    User? _user = ref.read(firebaseAuthProvider).currentUser;
    if (_user == null) {
      throw Exception("User not logged in");
    }

    DocumentSnapshot _userData = await ref
        .read(firebaseFirestoreProvider)
        .collection('users')
        .doc(_user.uid)
        .get();

    // Safely access user data with null checking
    Map<String, dynamic>? data = _userData.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("User data not found");
    }

    // Check for existing jobs
    var jobSnapshot = await ref
        .read(firebaseFirestoreProvider)
        .collection('jobs')
        .where('user id', isEqualTo: _user.uid)
        .where('job type', isEqualTo: DropdownValue)
        .get();

    if (jobSnapshot.docs.isNotEmpty) {
      print("Job already exists for this user and job type.");
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    while (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      var completer = Completer<void>();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Use your location'),
            content: Text('We need your location to add the job.'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  permission = await Geolocator.requestPermission();
                  if (permission != LocationPermission.denied &&
                      permission != LocationPermission.deniedForever) {
                    completer.complete();
                  }
                },
              ),
            ],
          );
        },
      );
      await completer.future;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Determine Expiry date
    DateTime expiryDate = DateTime.now().add(Duration(days: 30));

    // Safely get country or fetch it if not available
    String country = data['country'] ?? '';
    if (country.isEmpty) {
      country = await getCountryFromCoordinates(position.latitude, position.longitude);
    }

    // Batch write to ensure atomicity
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Update user document
    DocumentReference userRef = ref.read(firebaseFirestoreProvider)
        .collection('users')
        .doc(_user.uid);
    
    batch.update(userRef, {
      'position': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'had free trial': true,
      if (country.isNotEmpty) 'country': country, // Only update country if we have a value
    });

    // Create new job document
    DocumentReference jobRef = ref.read(firebaseFirestoreProvider)
        .collection('jobs')
        .doc(); // Auto-generate ID

    batch.set(jobRef, {
      'user id': _user.uid,
      'user name': data['fullName'] ?? '',
      'phone number': data['phone'] ?? '',
      'image url': data['image url'] ?? '',
      'job type': DropdownValue,
      'description': _descriptionController.text.trim(),
      'position': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'expiry date': expiryDate,
      'country': country,
    });

    // Commit the batch
    await batch.commit();

    print("Job successfully added!");

    _descriptionController.clear();
    Navigator.pop(context);
  } catch (e) {
    print("Error adding job: $e");
    // Show error dialog to user
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Failed to add job. Please try again later.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

Future<String> getCountryFromCoordinates(double latitude, double longitude) async {
  final url = 'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&accept-language=en';
  final response = await http.get(Uri.parse(url), headers: {
    'User-Agent': 'FlutterApp (your-email@example.com)' // Replace with your email for identification
  });

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final country = data['address']?['country'];
    return country ?? '';
  } else {
    print("Error: Unable to fetch country data, status code: ${response.statusCode}");
    return '';
  }
}

}
