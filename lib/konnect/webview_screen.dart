import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:panne_auto/pages/artisan_page/request_page.dart';
import 'package:panne_auto/providers/auth_providers.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'konnect_api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WebViewScreen extends ConsumerStatefulWidget {
  final String url;
  final String paymentId;
  final int amount;
  final String dropdownValue;

  WebViewScreen({required this.url, required this.paymentId,required this.amount,required this.dropdownValue});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends ConsumerState<WebViewScreen> {
  late WebViewController controller;
  final KonnectApiService _apiService = KonnectApiService();
  Timer? _timer;
  bool _isLoading = true;
  final TextEditingController _descriptionController = TextEditingController();
  /*String dropdownValue = 'Select Job Type';*/  // Example placeholder for dropdown

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print("Loading progress: $progress%");
          },
          onPageStarted: (String url) {
            print("Page started loading: $url");
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print("Page finished loading: $url");
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print("Web resource error: ${error.errorCode} - ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // Start polling for payment status
    _startPaymentStatusCheck();
  }

  // Poll payment status every 5 seconds
  void _startPaymentStatusCheck() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        final status = await _apiService.getPaymentStatus(widget.paymentId);
        if (status == "completed") {
          _timer?.cancel(); // Stop polling on success
          await AddJob();  // Call AddJob function on successful payment
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RequestPage()),
          );
        }
      } catch (e) {
        print("Error checking payment status: $e");
      }
    });
  }

  Future<void> AddJob() async {
  try {
    User? _user = ref.read(firebaseAuthProvider).currentUser;
    DocumentSnapshot _userData = await ref
        .read(firebaseFirestoreProvider)
        .collection('users')
        .doc(_user!.uid)
        .get();

    // Convert DocumentSnapshot to Map and add null check
    Map<String, dynamic>? userData = _userData.data() as Map<String, dynamic>?;
    if (userData == null) {
      throw Exception("User data not found");
    }

    var jobSnapshot = await ref
        .read(firebaseFirestoreProvider)
        .collection('jobs')
        .where('user id', isEqualTo: _user.uid)
        .where('job type', isEqualTo: widget.dropdownValue)
        .get();

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

    // Get country from coordinates
    String country = await getCountryFromCoordinates(
        position.latitude, position.longitude);

    // Determine Expiry date based on amount
    DateTime expiryDate;
    if (widget.amount == 20000) {
      expiryDate = DateTime.now().add(Duration(days: 30));
    } else if (widget.amount == 100000) {
      expiryDate = DateTime.now().add(Duration(days: 30 * 6));
    } else if (widget.amount == 160000) {
      expiryDate = DateTime.now().add(Duration(days: 30 * 12));
    } else {
      expiryDate = DateTime.now();
    }

    // Use WriteBatch for atomic operations
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Update user document
    DocumentReference userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid);
    
    batch.update(userRef, {
      'position': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      if (country.isNotEmpty) 'country': country, // Only update if country is not empty
    });

    // Create new job document
    DocumentReference jobRef = ref.read(firebaseFirestoreProvider)
        .collection('jobs')
        .doc();

    batch.set(jobRef, {
      'user id': _user.uid,
      'user name': userData['fullName'] ?? '',
      'phone number': userData['phone'] ?? '',
      'image url': userData['image url'] ?? '',
      'job type': widget.dropdownValue,
      'description': _descriptionController.text.trim(),
      'position': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'expiry date': expiryDate,
    });

    // Commit all operations
    await batch.commit();

    _descriptionController.clear();
    Navigator.pop(context);
  } catch (e) {
    print("Error adding job: $e");
    // Show error dialog
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

// Add this helper function to get country from coordinates
Future<String> getCountryFromCoordinates(double latitude, double longitude) async {
  try {
    final url = 'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&accept-language=en';
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'FlutterApp (your-email@example.com)' // Replace with your email
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final country = data['address']?['country'];
      return country ?? '';
    }
    return '';
  } catch (e) {
    print("Error fetching country: $e");
    return '';
  }
}


  @override
  void dispose() {
    _timer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
