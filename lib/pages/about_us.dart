import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SafeArea(
                child: Container(
                  height: size.height * 0.1,
                  child: Center(
                    child: Text(
                      "About Us",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
              child: Container(
                alignment: Alignment.center,
                height: size.height * 0.5,
                child: Text(
                  "Nous sommes une application mobile de mise en contact entre clients et artisans,"
                  " des services automobile. "
                  "Panne permet à ses clients de trouver des artisans plus disponibles et à ceux-ci d'avoir une flexibilité horaire qui leur donne l’occasion d’optimiser leur temps de travail."
                  " Elle offre une plateforme facile d'accès et simple d’utilisation pour garder à votre portée les moyens de résoudre le moindre problème.",
                  style: GoogleFonts.poppins(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Text(
              "Copyright © ${DateTime.now().year} ALAYA DIGITAL",
              style: GoogleFonts.poppins(),
            )
          ]),
        ),
      ),
    );
  }
}
