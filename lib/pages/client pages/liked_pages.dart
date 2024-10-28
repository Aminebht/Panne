import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:panne_auto/pages/chat/chat_page.dart';
import 'package:panne_auto/pages/client%20pages/details_page.dart';
import 'package:panne_auto/providers/auth_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LikePage extends ConsumerStatefulWidget {
  const LikePage({super.key});

  @override
  createState() => _LikePageState();
}

void openSMS(String phoneNumber) async {
  var url = Uri.parse('sms:$phoneNumber');
  if (await canLaunch(url.toString())) {
    await launch(url.toString());
  } else {
    throw 'Could not launch $url';
  }
}

class _LikePageState extends ConsumerState<LikePage> {
  Future<void> deleteLike(String jobId) async {
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
        // If the like document does not exist, do nothing
      }
    } catch (e) {
      print("Failed to delete the document: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    User? _user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                AppLocalizations.of(context)!.liked,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('likes')
                  .where('user id', isEqualTo: _user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: SpinningImage());
                }

                return FutureBuilder<List<DocumentSnapshot>>(
                  future: Future.wait(snapshot.data!.docs.map((like) {
                    return FirebaseFirestore.instance
                        .collection('jobs')
                        .doc(like['job id'])
                        .get();
                  }).toList()),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot jobSnapshot = snapshot.data![index];
                        Map<String, dynamic> job =
                            jobSnapshot.data() as Map<String, dynamic>;

                        return ListTile(
                          title: Text(
                            job['user name'],
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            job['phone number'].toString(),
                            style: GoogleFonts.poppins(),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize
                                .min, // This makes the Row as small as possible
                            children: <Widget>[
                              IconButton(
                                icon: Icon(
                                  FeatherIcons.messageCircle,
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        otherUserId: job['user id'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ).animate().shake(),
                                onPressed: () {
                                  deleteLike(jobSnapshot.id);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        DetailsPage(data: job)));
                          },
                        );
                      },
                    ).animate().slideX(duration: Duration(milliseconds: 250));
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
