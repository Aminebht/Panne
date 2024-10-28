import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:panne_auto/componant/button.dart';
import 'package:panne_auto/constants.dart';
import 'package:panne_auto/pages/chat/chat_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DetailsPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const DetailsPage({super.key, required this.data});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

Future<void> _makePhoneCall(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class _DetailsPageState extends State<DetailsPage> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    String? username = widget.data['user name'];
    String? phoneNumber = widget.data['phone number'];
    String description = widget.data['description'];
    String jobType = widget.data['job type'];
    String imageUrl = widget.data['image url'];

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: size.height * 0.2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40, right: 20, left: 20),
                  child: Image.asset(
                    constants.logoPath,
                    height: 50,
                    width: 50,
                  ),
                ),
              ],
            ),
          ),
          ClipOval(
            child: Image.network(
              imageUrl,
              height: 120,
              width: 120,
            ),
          ),
          SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Row(
              children: [
                Text('${AppLocalizations.of(context)!.name}:',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Flexible(
                    child:
                        Text(username ?? 'N/A', style: GoogleFonts.poppins())),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Row(
              children: [
                Text('${AppLocalizations.of(context)!.job_type}:',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Flexible(child: Text(jobType, style: GoogleFonts.poppins())),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Row(
              children: [
                Text('${AppLocalizations.of(context)!.description}:',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Flexible(
                    child: Text(description, style: GoogleFonts.poppins())),
              ],
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      otherUserId: widget.data['user id'],
                    ),
                  ),
                );
              },
              child: MainButton(
                  name: 'Contact now'), // Update the button text to "Chat Now"
            ),
          ),
        ],
      ),
    );
  }
}
