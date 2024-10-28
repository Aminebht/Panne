import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:panne_auto/componant/artisan_bottom_navbar.dart';
import 'package:panne_auto/componant/button.dart';
import 'package:panne_auto/componant/button_navbar.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:panne_auto/constants.dart';
import 'package:panne_auto/pages/Forgot_password.dart';
import 'package:panne_auto/pages/google_facebook_page.dart';
import 'package:panne_auto/pages/signup_page.dart';
import 'package:panne_auto/providers/auth_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../main.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

bool _obscureText = true;

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> signInWithGoogle() async {
    try {
      // Trigger the Google Authentication flow.
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // If the user successfully signs in.
      if (googleUser != null) {
        // Obtain the auth details from the request.
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential.
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google [UserCredential].
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        // The user's ID, unique to the Firebase project. Do NOT use
        // this value to authenticate with your backend server, if you
        // have one. Use User.getToken() instead.
        final User? user = userCredential.user;

        if (user != null) {
          // Check if user's info exists in Firestore.
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userSnapshot.exists) {
            String userType = userSnapshot['user type'];
            String name = userSnapshot['fullName'];
            print("User Type: $userType");
            print(name);

            ZegoUIKitPrebuiltCallInvitationService().init(
              appID: 312542080 /*input your AppID*/,
              appSign:
                  '802ecb8248d6db0dcdbd071a1eed951a85c43c79128f8ef263679425b591700d' /*input your AppSign*/,
              userID: user.uid,
              userName: name,
              plugins: [ZegoUIKitSignalingPlugin()],
            );

            // Navigate to the corresponding page based on user type.
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
          } else {
            // User's data doesn't exist in Firestore, navigate them to the additional info page.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => NewUserDetailsPage(user: user)),
            );
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> signIn() async {
    setState(() {
      _isLoading = true; // Set loading status to true when sign-in starts
    });

    try {
      UserCredential userCredential =
          await ref.read(firebaseAuthProvider).signInWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              );

      User? user = userCredential.user;

      if (user != null) {
        print("Signed-in User UID: ${user.uid}");

        DocumentSnapshot userSnapshot = await ref
            .read(firebaseFirestoreProvider)
            .collection('users')
            .doc(user.uid)
            .get();

        if (userSnapshot.exists) {
          String userType = userSnapshot['user type'];
          String name = userSnapshot['fullName'];
          print("User Type: $userType");
          print(name);

          ZegoUIKitPrebuiltCallInvitationService().init(
            appID: 312542080 /*input your AppID*/,
            appSign:
                '802ecb8248d6db0dcdbd071a1eed951a85c43c79128f8ef263679425b591700d' /*input your AppSign*/,
            userID: user.uid,
            userName: name,
            plugins: [ZegoUIKitSignalingPlugin()],
          );

          // Navigate to the corresponding page based on user type.
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
        } else {
          print("User snapshot does not exist for UID: ${user.uid}");
        }
      } else {
        print("User is null");
      }
    } catch (e) {
      // Handle sign-in errors here, e.g., show a snackbar or display an error message.
      print("Sign-in error: $e");
      // Show a snackbar with the error message.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign-in error: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading status to false when sign-in ends
      });
    }
  }

  void _showLanguageSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: <Widget>[
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.select_language,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
              _buildLanguageOption(
                  context, AppLocalizations.of(context)!.english, Locale('en')),
              _buildLanguageOption(
                  context, AppLocalizations.of(context)!.french, Locale('fr')),
              _buildLanguageOption(
                  context, AppLocalizations.of(context)!.arabic, Locale('ar')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
      BuildContext context, String languageName, Locale locale) {
    return ListTile(
      title: Text(languageName),
      onTap: () {
        MyApp.changeLanguage(context, locale);
        Navigator.of(context)
            .pop(); // Close the language selection bottom sheet
      },
    );
  }

  @override
  void dispose() {
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
            Stack(children: [
              Container(
                height: size.height * 0.3 - 30,
                width: size.width,
                child: Padding(
                  padding: const EdgeInsets.only(top: 70, bottom: 70),
                  child: Image.asset(
                    constants.logoPath2,
                    height: 50,
                    width: 50,
                  ),
                ),
              ),
              Positioned(
                top: 70,
                left: 30,
                child: GestureDetector(
                  onTap: () {
                    _showLanguageSelection(context);
                  },
                  child: Image.asset(
                    "assets/icons/language.png",
                    height: 28,
                  ),
                ),
              ).animate().shake(duration: Duration(milliseconds: 1500)),
            ]),
            Container(
              height: size.height * 0.5,
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 45, right: 45, top: 80),
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
                    ).animate().slideX(),
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
                    ).animate().slideX(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 50),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ForgotPassword()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 40, right: 20),
                            child: Text(
                              AppLocalizations.of(context)!.forgot_password,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.normal, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                      padding: EdgeInsets.only(top: size.height * 0.1 - 40),
                      child: GestureDetector(
                          onTap: () async {
                            await signIn();
                          },
                          child: _isLoading
                              ? SpinningImage()
                              : MainButton(
                                  name: AppLocalizations.of(context)!.login,
                                ))),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.account,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.normal, fontSize: 18),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignupPage()),
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)!.signup,
                            style: GoogleFonts.poppins(
                                color: Color(0xFF235A81),
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.withh,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.normal),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 100, right: 100, top: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                      onTap: signInWithGoogle,
                      child:
                          Image.asset('assets/icons/icons8-google-100 1.png'))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
