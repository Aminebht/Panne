import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panne_auto/componant/artisan_bottom_navbar.dart';
import 'package:panne_auto/componant/button.dart';
import 'package:panne_auto/componant/button_navbar.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:panne_auto/constants.dart';
import 'package:panne_auto/pages/login_page.dart';
import 'package:panne_auto/providers/auth_providers.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

bool _obscureText = true;

class _SignupPageState extends ConsumerState<SignupPage> {
  final _fullnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _selectedUserType = '';
  double _buttonScale = 1.0;

  Future<void> Register(String userType) async {
    setState(() {
      _isLoading = true; // Set loading status to true when registration starts
    });
    try {
      await ref.read(firebaseAuthProvider).createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      String? token = await FirebaseMessaging.instance.getToken();

      await addUserDetails(
          _fullnameController.text.trim(),
          _phoneController.text.trim(),
          _emailController.text.trim(),
          userType,
          token);

      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: 312542080,
        appSign:
            '802ecb8248d6db0dcdbd071a1eed951a85c43c79128f8ef263679425b591700d',
        userID: ref.read(firebaseAuthProvider).currentUser?.uid ?? '',
        userName: _fullnameController.text.trim(),
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

  Future<void> addUserDetails(String fullName, String phone, String email,
      String userType, String? token) async {
    User? user = ref.read(firebaseAuthProvider).currentUser;
    String imageUrl =
        'https://firebasestorage.googleapis.com/v0/b/panneauto-b3561.appspot.com/o/man.png?alt=media&token=12e549f6-705e-4c23-8b84-6499de713a9c';
    await ref
        .read(firebaseFirestoreProvider)
        .collection('users')
        .doc(user?.uid)
        .set({
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'user type': userType,
      'image url': imageUrl,
      'position': {
        'latitude': '0',
        'longitude': '0',
      },
      'token': token,
    });
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
  void dispose() {
    _phoneController.dispose();
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: size.height * 0.3 - 60,
              width: size.width,
              child: Padding(
                padding: const EdgeInsets.all(50),
                child: Image.asset(
                  constants.logoPath2,
                ),
              ),
            ),
            Container(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 45, right: 45, top: 50),
                    child: TextField(
                      controller: _fullnameController,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.name,
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
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 45, right: 45, top: 32),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.bold),
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
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 45, right: 45, top: 32),
                    child: TextField(
                      controller: _emailController,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.email,
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
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 45, right: 45, top: 30),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.password,
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
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey, // Choose the icon color
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText =
                                  !_obscureText; // Toggle the visibility state
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 50),
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
                            scale: _selectedUserType == 'Client'
                                ? 1.1
                                : _buttonScale,
                            child: Container(
                              width: 140,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                            AppLocalizations.of(context)!
                                                .client,
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
                                        AppLocalizations.of(context)!
                                            .description_client,
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
                            scale: _selectedUserType == 'Artisan'
                                ? 1.1
                                : _buttonScale,
                            child: Container(
                              width: 140,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                            AppLocalizations.of(context)!
                                                .artison,
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
                                        AppLocalizations.of(context)!
                                            .description_artisan,
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
                  GestureDetector(
                    onTap: () async {
                      await Register(_selectedUserType);
                    },
                    child: _isLoading
                        ? SpinningImage()
                        : MainButton(
                            name: AppLocalizations.of(context)!.register,
                          ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.accountt,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.normal, fontSize: 18),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)!.sign_in,
                          style: GoogleFonts.poppins(
                              color: Color(0xFF235A81),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
