import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserConditions extends StatelessWidget {
  const UserConditions({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: SafeArea(
              child: Container(
                height: size.height * 0.1,
                child: Center(
                  child: Text(
                    "User Conditions",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: Text(
                "L'application (Panne Auto) est la propriété de la  société (ALAYA DIGITAL)."
                "\n\nL'idée, le logo et le nom (Panne)  de l'application ont le copyright par l'OTDAV (Organisme tunisien des droits d’autres et des droits voisins)."
                "\n\nNotre service offre une mise en relation entre artisan indépendant et client pour permettre à l'utilisateur de trouver de l'aide dans les plus brefs délais."
                "\n\nPanne utilise le service de localisation de votre téléphone dans un rayon de 100 km."
                "\n\nLors de l'inscription le nom , le prénom , le numéro de téléphone et l'email sont obligatoires ainsi que l'enregistrement de votre géolocalisation."
                "\n\nLe client est le seul responsable de ces informations lors de la mise en contact avec l'artisan par appel ou SMS (directement sur son numéro de téléphone)."
                "\n\nEn cas d'accord entre les deux parties, l'application n'intervient pas dans le coût ou la tarification des prestations."
                "\n\nLe client peut envoyer ou bien affirmer son adresse exacte et ainsi d'informations pour le service."
                "\n\nL'artisan aussi peut envoyer et affirmer son adresse exacte si le service choisi nécessite ces informations."
                "\n\nUne fois que le client et l'artisan sont mis en contact l'application atteint son objectif et n'interviendra plus dans l'accord et le service.",
                style: GoogleFonts.poppins(),
              ),
            ),
          )
        ]),
      ),
    );
  }
}
