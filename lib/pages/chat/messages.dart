import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panne_auto/pages/chat/chat_page.dart'; // Import your chat screen
import 'package:shimmer/shimmer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SentMessagesScreen extends StatefulWidget {
  @override
  State<SentMessagesScreen> createState() => _SentMessagesScreenState();
}

class _SentMessagesScreenState extends State<SentMessagesScreen> {
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: _user.uid)
            .orderBy('lastMessageAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text(AppLocalizations.of(context)!.no_messages));
          }

          return Column(
            children: <Widget>[
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    AppLocalizations.of(context)!.your_chats,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot chatDoc = snapshot.data!.docs[index];
                    String otherUserId = chatDoc['participants']
                        .firstWhere((userId) => userId != _user.uid);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(otherUserId)
                          .get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: ListTile(
                              title: Container(
                                color: Colors.white,
                                width: double.infinity,
                                height: 10.0,
                              ),
                              subtitle: Container(
                                color: Colors.white,
                                width: double.infinity,
                                height: 10.0,
                              ),
                              leading: ClipOval(
                                child: Container(
                                  color: Colors.white,
                                  width: 50.0,
                                  height: 50.0,
                                ),
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Text("Document does not exist");
                        }

                        Map<String, dynamic> data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        bool isOnline = data['isOnline'] ?? false;
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('chats')
                              .doc(chatDoc.id)
                              .collection('messages')
                              .orderBy('sentAt', descending: true)
                              .limit(1)
                              .snapshots(),
                          builder: (BuildContext context,
                              AsyncSnapshot<QuerySnapshot> messageSnapshot) {
                            if (messageSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: ListTile(
                                  title: Container(
                                    color: Colors.white,
                                    width: double.infinity,
                                    height: 10.0,
                                  ),
                                  subtitle: Container(
                                    color: Colors.white,
                                    width: double.infinity,
                                    height: 10.0,
                                  ),
                                  leading: ClipOval(
                                    child: Container(
                                      color: Colors.white,
                                      width: 50.0,
                                      height: 50.0,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (messageSnapshot.hasError) {
                              return Text("Something went wrong");
                            }

                            if (messageSnapshot.data!.docs.isEmpty) {
                              // Handle the case when there are no messages
                              return SizedBox(); // or any other placeholder/widget
                            }

                            final messageData = messageSnapshot.data!.docs.first
                                .data() as Map<String, dynamic>;
                            final bool messageSeen =
                                messageData['seenByReceiver'] ?? false;
                            final bool messageSentByOtherUser =
                                messageData['senderId'] != _user.uid;

                            String message;
                            if (messageData['text'] != null) {
                              message = messageData['text'];
                            } else if (messageData['imageUrl'] != null) {
                              message =
                                  AppLocalizations.of(context)!.image_message;
                            } else if (messageData['callType'] != null) {
                              message = AppLocalizations.of(context)!.call;
                            } else {
                              message =
                                  AppLocalizations.of(context)!.voice_message;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, right: 8, bottom: 8),
                              child: ListTile(
                                title: Text(
                                  data['fullName'].length > 20
                                      ? '${data['fullName'].substring(0, 20)}...'
                                      : data['fullName'],
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  message.length > 30
                                      ? '${message.substring(0, 30)}...'
                                      : message,
                                  style: GoogleFonts.poppins(
                                    fontWeight: (!messageSeen &&
                                            messageSentByOtherUser)
                                        ? FontWeight
                                            .bold // Make the text bold if the message is unseen and sent by the other user
                                        : FontWeight
                                            .normal, // Otherwise, make the text normal
                                    color: Colors
                                        .grey[700], // Set the color to gray
                                  ),
                                ),
                                leading: Stack(
                                  children: [
                                    ClipOval(
                                      child: Image.network(data['image url']),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: isOnline
                                          ? Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.green,
                                              ),
                                            )
                                          : Container(),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        otherUserId: otherUserId,
                                      ),
                                    ),
                                  );
                                },
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
          );
        },
      ),
    );
  }
}
