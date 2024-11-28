import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panne_auto/componant/button.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:panne_auto/constants.dart';
import 'package:panne_auto/pages/login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> sendPasswordResetEmail(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      print('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      print('Failed to send password reset email: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    // ignore: use_build_context_synchronously
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: SingleChildScrollView(
            child: Column(children: [
      // ignore: sized_box_for_whitespace
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
          controller: _emailController,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.email,
            hintStyle: GoogleFonts.poppins(
                color: const Color(0xFF000000).withOpacity(0.4),
                fontWeight: FontWeight.bold,
                fontSize: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: const BorderSide(
                color: Color(0xFF235A81),
                width: 3.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: const BorderSide(
                color: Color(0xFF235A81),
                width: 3.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 16.0), // Adjust height and left spacing
            isDense: true,
          ),
        ).animate().slideX(),
      ),
      Padding(
          padding: EdgeInsets.only(top: size.height * 0.2),
          child: GestureDetector(
              onTap: () async {
                await sendPasswordResetEmail(context);
              },
              child: _isLoading
                  ? SpinningImage()
                  : MainButton(
                      name: AppLocalizations.of(context)!.link,
                    )))
    ])));
  }
}
