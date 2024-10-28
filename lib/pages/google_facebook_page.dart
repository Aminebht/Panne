import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panne_auto/componant/artisan_bottom_navbar.dart';
import 'package:panne_auto/componant/button.dart';
import 'package:panne_auto/componant/button_navbar.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:panne_auto/constants.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NewUserDetailsPage extends StatefulWidget {
  final User user;
  const NewUserDetailsPage({super.key, required this.user});

  @override
  State<NewUserDetailsPage> createState() => _NewUserDetailsPageState();
}

class _NewUserDetailsPageState extends State<NewUserDetailsPage> {
  String _selectedUserType = '';
  double _buttonScale = 1.0;
  bool _isLoading = false;
  final _phoneNumberController = TextEditingController();

  Future<void> addUserDetails() async {
    String imageUrl =
        'https://firebasestorage.googleapis.com/v0/b/panneauto-b3561.appspot.com/o/man.png?alt=media&token=12e549f6-705e-4c23-8b84-6499de713a9c';

    String? token = await FirebaseMessaging.instance.getToken();
    // Add user details to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .set({
      'fullName': widget.user.displayName,
      'phone': _phoneNumberController.text.trim(),
      'email': widget.user.email,
      'user type': _selectedUserType,
      'image url': imageUrl,
      'position': {
        'latitude': '0',
        'longitude': '0',
      },
      'token': token,
    }, SetOptions(merge: true));
  }

  Future<void> register(String userType) async {
    setState(() {
      _isLoading = true; // Set loading status to true when registration starts
    });
    try {
      await addUserDetails();

      User userr = FirebaseAuth.instance.currentUser!;

      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: 312542080,
        appSign:
            '802ecb8248d6db0dcdbd071a1eed951a85c43c79128f8ef263679425b591700d',
        userID: userr.uid,
        userName: widget.user.displayName ?? 'Default User Name',
        plugins: [ZegoUIKitSignalingPlugin()],
      );

      // Navigate to the HomePage only if registration is successful.
      if (userType == 'Client') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomNavBar()),
        );
      } else if (userType == 'Artisan') {
        // Replace 'ArtisanPage' with the actual page for artisans.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ArtisanNavbar()),
        );
      }
    } catch (e) {
      // Handle registration errors here, e.g., show a snackbar or display an error message.
      print("Registration error: $e");
    } finally {
      setState(() {
        _isLoading =
            false; // Set loading status to false when registration ends
      });
    }
  }

  void _selectUserType(String userType) {
    setState(() {
      _selectedUserType = userType;
    });
  }

  void _scaleButton(double scale) {
    setState(() {
      _buttonScale = scale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        body: Column(children: [
      Container(
        height: size.height * 0.3 - 30,
        width: size.width,
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Image.asset(
            constants.logoPath2,
            scale: 0.4,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 45, right: 45, top: 80),
        child: TextField(
          controller: _phoneNumberController,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.phone,
            hintStyle: GoogleFonts.poppins(
                color: Color(0xFF000000).withOpacity(0.4),
                fontWeight: FontWeight.bold,
                fontSize: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide(
                color: Color(0xFF235A81),
                width: 3.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide(
                color: Color(0xFF235A81),
                width: 3.0,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 16.0), // Adjust height and left spacing
            isDense: true,
          ),
        ).animate().slideX(),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTapDown: (_) {
                _scaleButton(0.9);
              },
              onTapUp: (_) {
                _scaleButton(1.0);
                _selectUserType('Client');
              },
              onTapCancel: () {
                _scaleButton(1.0);
              },
              child: Transform.scale(
                scale: _selectedUserType == 'Client' ? 1.1 : _buttonScale,
                child: Container(
                  width: 140,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                height: 18,
                                width: 18,
                                'assets/icons/zoom.png',
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                AppLocalizations.of(context)!.client,
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            AppLocalizations.of(context)!.description_client,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFE29100),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _selectedUserType == 'Client'
                          ? Colors.black
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTapDown: (_) {
                _scaleButton(0.9);
              },
              onTapUp: (_) {
                _scaleButton(1.0);
                _selectUserType('Artisan');
              },
              onTapCancel: () {
                _scaleButton(1.0);
              },
              child: Transform.scale(
                scale: _selectedUserType == 'Artisan' ? 1.1 : _buttonScale,
                child: Container(
                  width: 140,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                height: 18,
                                width: 18,
                                'assets/icons/mechanic.png',
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                AppLocalizations.of(context)!.artison,
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white
                                    // _selectedUserType == 'Artisan'
                                    //     ? Colors.white
                                    //     : Colors.white,
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            AppLocalizations.of(context)!.description_artisan,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF235A81),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _selectedUserType == 'Artisan'
                          ? Colors.black
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
          padding: EdgeInsets.only(top: size.height * 0.2),
          child: GestureDetector(
              onTap: () async {
                await register(_selectedUserType);
              },
              child: _isLoading
                  ? SpinningImage()
                  : MainButton(
                      name: AppLocalizations.of(context)!.register,
                    )))
    ]));
  }
}
