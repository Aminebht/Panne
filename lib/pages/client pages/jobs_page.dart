import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panne_auto/componant/AdMob.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:panne_auto/constants.dart';
import 'package:panne_auto/pages/client%20pages/CustomSearchDelegate.dart';
import 'package:panne_auto/pages/client%20pages/details_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:panne_auto/providers/auth_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class JobsPage extends ConsumerStatefulWidget {
  final String category;
  const JobsPage({super.key, required this.category});

  @override
  createState() => _JobsPageState();
}

class _JobsPageState extends ConsumerState<JobsPage> {
  Stream<QuerySnapshot<Object?>> jobStream =
      FirebaseFirestore.instance.collection('jobs').snapshots();
  int selectedDistance = 1;
  List<int> distances = [1, 5, 10, 20, 50];
  User? _user = FirebaseAuth.instance.currentUser;
  StreamController<void> _streamController = StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
  }

  void handlePhoneCall(String? phoneNumber) async {
    if (phoneNumber != null) {
      final Uri phoneUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      try {
        await launchUrl(phoneUri);
      } catch (e) {
        print('Could not launch $phoneUri');
      }
    } else {
      print('Phone number is not available.');
    }
  }

  Future<void> checkLocationPermission() async {
    LocationPermission? permission = await Geolocator.checkPermission();
    while (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await showDialog<LocationPermission>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Use your location',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logos/map.png', height: 100, width: 100),
                SizedBox(
                  height: 20,
                ),
                Text(
                  'Panne.auto collects location data to enable Addjob, and ViewJobs even when the app is closed or not in use.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
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
                  Navigator.of(context).pop(); // Close the dialog first
                  permission = await Geolocator.requestPermission()
                      as LocationPermission?;
                  if (permission != LocationPermission.denied &&
                      permission != LocationPermission.deniedForever) {
                    _streamController
                        .add(null); // Trigger a rebuild of the StreamBuilder
                  }
                },
              ),
            ],
          );
        },
      );
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  Stream<List<DocumentSnapshot>> getUserJobs(String category) async* {
    User? user = FirebaseAuth.instance.currentUser;

    // Check location permissions

    // Get the user's current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
      'position': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
    });

    // Fetch all jobs from Firestore
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .where('job type', isEqualTo: category)
        .get();

    // Filter the jobs based on distance
    final jobs = querySnapshot.docs.where((job) {
      GeoPoint jobPosition =
          GeoPoint(job['position']['latitude'], job['position']['longitude']);
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        jobPosition.latitude,
        jobPosition.longitude,
      );
      return distanceInMeters / 1000 <=
          selectedDistance; // Convert to km and check if within 50km
    }).toList();

    yield jobs;
  }

  Future<void> toggleLike(String jobId) async {
    try {
      User? _user = ref.read(firebaseAuthProvider).currentUser;

      // Get a reference to the like document
      DocumentReference likeRef = ref
          .read(firebaseFirestoreProvider)
          .collection('likes')
          .doc('${_user?.uid}_$jobId');

      DocumentSnapshot likeSnapshot = await likeRef.get();

      if (likeSnapshot.exists) {
        // If the like document exists, delete it
        await likeRef.delete();
      } else {
        // If the like document does not exist, create it
        await likeRef.set({
          'user id': _user?.uid,
          'job id': jobId,
        });
      }

      print('Job like toggled successfully');
    } catch (e) {
      print('Failed to toggle job like: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: size.height * 0.2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
                  child: Image.asset(
                    constants.logoPath,
                    height: 50,
                    width: 50,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.category,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 24),
                ).animate().slideX().then().shimmer(),
                DropdownButton<int>(
                  value: selectedDistance,
                  icon: Icon(Icons.arrow_downward),
                  onChanged: (int? newValue) {
                    setState(() {
                      selectedDistance = newValue!;
                    });
                  },
                  items: distances.map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value km'),
                    );
                  }).toList(),
                ).animate().shake()
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: checkLocationPermission(),
              builder: (context, snapshot) {
                // Show loading indicator while waiting for checkLocationPermission
                if (snapshot.connectionState != ConnectionState.done) {
                  return Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<void>(
                  stream: _streamController.stream,
                  builder: (context, _) {
                    return StreamBuilder<List<DocumentSnapshot>>(
                      stream: getUserJobs(widget.category),
                      builder: (context, snapshot) {
                        // Show loading indicator while waiting for getUserJobs
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: SpinningImage());
                        }

                        if (snapshot.hasError) {
                          print('Error: ${snapshot.error}');
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/logos/warning.png",
                                height: 150,
                                width: 150,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],
                          );
                        }

                        return Material(
                          child: ListView(
                            children:
                                snapshot.data!.map((DocumentSnapshot document) {
                              Map<String, dynamic> data =
                                  document.data() as Map<String, dynamic>;
                              String? username = data['user name'];
                              String? phoneNumber = data['phone number'];
                              String? userId = data['user id'];

                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .get(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.done) {
                                    Map<String, dynamic> userData =
                                        snapshot.data!.data()
                                            as Map<String, dynamic>;
                                    bool isOnline =
                                        userData['isOnline'] ?? false;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Container(
                                        margin: EdgeInsets.all(10.0),
                                        padding: EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF235A81),
                                              Color(0xFF235A81),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        child: ListTile(
                                          title: Row(
                                            children: [
                                              isOnline
                                                  ? Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors
                                                            .green, // Set the color of the dot to green
                                                      ),
                                                    )
                                                  : Container(),
                                              isOnline
                                                  ? SizedBox(width: 8)
                                                  : SizedBox(
                                                      width:
                                                          0), // Add some spacing between the dot and the text
                                              Text(
                                                (username ?? 'N/A'),
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: GestureDetector(
                                            onTap: isOnline
                                                ? null
                                                : () => handlePhoneCall(
                                                    phoneNumber),
                                            child: Container(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5),
                                                child: Text(
                                                  'Phone Number: ' +
                                                      (phoneNumber
                                                              ?.toString() ??
                                                          'N/A'),
                                                  style: GoogleFonts.poppins(
                                                    color: isOnline
                                                        ? Colors.black
                                                        : Colors
                                                            .blue, // Highlight the phone number if the user is offline
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          trailing:
                                              StreamBuilder<DocumentSnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection('likes')
                                                .doc(
                                                    '${_user?.uid}_${document.id}')
                                                .snapshots(),
                                            builder: (context, snapshot) {
                                              bool isLiked = snapshot.hasData &&
                                                  snapshot.data!.exists;
                                              return IconButton(
                                                icon: Icon(Icons.favorite),
                                                color:
                                                    isLiked ? Colors.red : null,
                                                onPressed: () {
                                                  toggleLike(document.id);
                                                },
                                              );
                                            },
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) {
                                                return DetailsPage(data: data);
                                              }),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Add a loading indicator or some other placeholder here...
                                    return CircularProgressIndicator();
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
