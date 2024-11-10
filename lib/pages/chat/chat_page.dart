import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:panne_auto/componant/audio_component.dart';
import 'package:panne_auto/constants.dart';
import 'package:panne_auto/pages/chat/call_page.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:googleapis_auth/auth.dart' as auth;

class ChatScreen extends StatefulWidget {
  final String otherUserId;

  ChatScreen({required this.otherUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late String chatId;
  late Future<DocumentSnapshot> otherUserFuture;
  FlutterSoundRecorder? _recorder;

  @override
  void initState() {
    super.initState();

    _recorder = FlutterSoundRecorder();
    _openAudioSession();
    // Generate chat ID based on both user IDs
    chatId = _generateChatId(
      FirebaseAuth.instance.currentUser!.uid,
      widget.otherUserId,
    );
    otherUserFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .get();
  }

  void _openAudioSession() async {
    await _recorder!.openAudioSession();
  }

  String _generateChatId(String userId1, String userId2) {
    // Sort user IDs alphabetically to ensure consistency
    List<String> userIds = [userId1, userId2]..sort();
    return userIds.join('_');
  }

  @override
  void dispose() {
    _recorder!.closeAudioSession();
    _recorder = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? _user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: Column(
        children: <Widget>[
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Image.asset('assets/icons/backarrow.png'),
                  ),
                  SizedBox(width: 20),
                  FutureBuilder<DocumentSnapshot>(
                    future: otherUserFuture,
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.hasData) {
                        Map<String, dynamic> data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        return Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    NetworkImage(data['image url']),
                              ),
                              SizedBox(width: 10),
                              Text(
                                (data['fullName'] ?? '').length > 15
                                    ? '${(data['fullName'] ?? '').substring(0, 15)}...'
                                    : data['fullName'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      }
                      return CircularProgressIndicator();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ZegoSendCallInvitationButton(
                      iconSize: Size(30.0, 30.0),
                      buttonSize: Size(30.0, 30.0),
                      icon: ButtonIcon(
                        icon: Icon(
                          Icons.call, // Replace with your actual icon
                          color: Color(0xFFE29100),
                        ),
                      ),
                      onPressed: _logCallEvent,
                      isVideoCall: false,
                      resourceID:
                          "panne_auto", //You need to use the resourceID that you created in the subsequent steps. Please continue reading this document.
                      invitees: [
                        ZegoUIKitUser(
                          id: widget.otherUserId,
                          name: '',
                        ),
                      ],
                    ),
                  ),
                  // IconButton(
                  //   icon: Icon(
                  //     Icons.call,
                  //     color: Color(0xFFE29100),
                  //   ),
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //           builder: (context) => CallPage(
                  //                 callID: '1',
                  //                 userID: widget.otherUserId,
                  //                 userName: '',
                  //               )),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('sentAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
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

                List<DocumentSnapshot> messageDocs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messageDocs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> messageData =
                        messageDocs[index].data() as Map<String, dynamic>;
                    final bool isSentByCurrentUser =
                        messageData['senderId'] == _user!.uid;
                    final bool isLastMessage = index == 0;

                    if (messageData['senderId'] == widget.otherUserId &&
                        messageData['seenByReceiver'] == false) {
                      // Update the 'seenByReceiver' field to true
                      messageDocs[index]
                          .reference
                          .update({'seenByReceiver': true});
                    }

                    return GestureDetector(
                      onLongPress: () {
                        // Show delete icon or perform deletion logic
                        _showDeleteMessageDialog(messageDocs[index]);
                      },
                      child: _buildMessageContainer(
                        messageData,
                        isSentByCurrentUser,
                        isLastMessage,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Enter a Message...",
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Fluttertoast.showToast(
                        msg: AppLocalizations.of(context)!.record,
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.grey,
                        textColor: Colors.white,
                        fontSize: 16.0);
                  },
                  onLongPress: () async {
                    await _startVoiceRecording();
                    Fluttertoast.showToast(
                        msg: AppLocalizations.of(context)!.recording,
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.grey,
                        textColor: Colors.white,
                        fontSize: 16.0);
                  },
                  onLongPressEnd: (details) async {
                    String? filePath = await _stopVoiceRecording();
                    if (filePath != null && filePath.isNotEmpty) {
                      _sendVoiceMessage(filePath);
                    }
                    Fluttertoast
                        .cancel(); // This will cancel all the active toasts
                  },
                  child: Icon(Icons.mic),
                ),
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _sendImageMessage,
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContainer(
    Map<String, dynamic> messageData,
    bool isSentByCurrentUser,
    bool isLastMessage,
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(messageData['senderId'])
          .get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasData) {
          Map<String, dynamic> senderData =
              snapshot.data!.data() as Map<String, dynamic>;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: isSentByCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isSentByCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(senderData['image url']),
                    ),
                  ),
                SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isSentByCurrentUser
                          ? Color(0xFFE29100)
                          : Color(0xFF2A709F),
                    ),
                    child: Column(
                      crossAxisAlignment: isSentByCurrentUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (messageData['text'] != null)
                          Text(
                            messageData['text'],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: isSentByCurrentUser
                                  ? Colors.white
                                  : Colors.white,
                            ),
                          )
                        else if (messageData['callType'] != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.call,
                                color: isSentByCurrentUser
                                    ? Colors.white
                                    : Colors.white,
                              ),
                              Text(
                                'Call event ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSentByCurrentUser
                                      ? Colors.white
                                      : Colors.white,
                                ),
                              ),
                            ],
                          )
                        else if (messageData['voiceMessageUrl'] != null)
                          AudioPlayerWidget(
                            key: Key(messageData['voiceMessageUrl']),
                            url: messageData['voiceMessageUrl'],
                          )
                        else if (messageData['imageUrl'] != null)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PhotoView(
                                      imageProvider:
                                          NetworkImage(messageData['imageUrl']),
                                    ),
                                  ));
                            },
                            child: Image.network(
                              messageData['imageUrl'],
                              fit: BoxFit.cover,
                            ),
                          ),
                        Text(
                          'Sent at: ${messageData['sentAt'].toDate()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSentByCurrentUser
                                ? Colors.white70
                                : Colors.white,
                          ),
                        ),
                        if (isLastMessage &&
                            isSentByCurrentUser &&
                            (messageData['seenByReceiver']))
                          Text(
                            'Seen',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }
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
      },
    );
  }

  Future<String> _startVoiceRecording() async {
    try {
      // Request microphone permission
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          // Permission denied, handle accordingly
          print('Microphone permission denied');
          return '';
        }
      }

      // Check if the recorder is still recording
      if (_recorder != null && _recorder!.isRecording) {
        await _recorder!.stopRecorder();
      }

      Directory tempDir = await getTemporaryDirectory();
      String filePath =
          '${tempDir.path}/voice_message_${DateTime.now().microsecondsSinceEpoch}.aac';

      await _recorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      return filePath;
    } catch (e) {
      print('Error starting voice recording: $e');
      return ''; // Return an empty string or handle the error accordingly
    }
  }

  Future<String?> _stopVoiceRecording() async {
    if (_recorder != null) {
      return await _recorder!.stopRecorder();
    }
    return null;
  }

  void _sendVoiceMessage(String filePath) async {
    print('Sending voice message from file: $filePath');

    User? _user = FirebaseAuth.instance.currentUser;

    // Create a reference to the file location in Firebase Storage
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('voice_messages')
        .child('${_user!.uid}_${Timestamp.now()}');

    // Upload the file to Firebase Storage
    UploadTask uploadTask = ref.putFile(File(filePath));

    // Get the download URL for the uploaded file
    String downloadURL = await (await uploadTask).ref.getDownloadURL();

    // Create the message data
    Map<String, dynamic> messageData = {
      'voiceMessageUrl': downloadURL,
      'sentAt': Timestamp.now(),
      'senderId': _user.uid,
      'receiverId': widget.otherUserId,
      'seenBySender': true,
      'seenByReceiver': false,
    };

    // Save the message data in Firestore
    DocumentReference chatDoc =
        FirebaseFirestore.instance.collection('chats').doc(chatId);

    chatDoc.collection('messages').add(messageData).then((value) {
      print('Voice message sent successfully.');

      _sendNotification(widget.otherUserId, 'Voice message');

      // Update 'lastMessageAt' in the chat document after sending a voice message
      chatDoc.update({
        'lastMessageAt': Timestamp.now(),
      }).then((value) {
        print("'lastMessageAt' updated successfully.");
      }).catchError((error) {
        print("Failed to update 'lastMessageAt': $error");
      });
    }).catchError((error) {
      print('Failed to send voice message: $error');
    });
  }

  void _sendImageMessage() async {
    User? _user = FirebaseAuth.instance.currentUser;
    final ImagePicker _picker = ImagePicker();
    // Pick an image
    final XFile? imageFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      // Create a reference to the location you want to upload to in Firebase Storage
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child("chat_images")
          .child("${_user!.uid}_${Timestamp.now()}");

      // Upload the file to Firebase Storage
      UploadTask uploadTask = storageReference.putFile(File(imageFile.path));

      // Get the download URL for the uploaded file
      String downloadURL = await (await uploadTask).ref.getDownloadURL();

      // Create the message data
      Map<String, dynamic> messageData = {
        'imageUrl': downloadURL,
        'sentAt': Timestamp.now(),
        'senderId': _user!.uid,
        'receiverId': widget.otherUserId,
        'seenBySender': true,
        'seenByReceiver': false,
      };

      // Save the message data in Firestore
      DocumentReference chatDoc =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      chatDoc.collection('messages').add(messageData).then((value) {
        print('Image message sent successfully.');

        _sendNotification(widget.otherUserId, 'Image message');

        // Update 'lastMessageAt' in the chat document after sending an image message
        chatDoc.update({
          'lastMessageAt': Timestamp.now(),
        }).then((value) {
          print("'lastMessageAt' updated successfully.");
        }).catchError((error) {
          print("Failed to update 'lastMessageAt': $error");
        });
      }).catchError((error) {
        print('Failed to send image message: $error');
      });
    } else {
      print('No image selected.');
    }
  }

void _logCallEvent(
    String code, String message, List<String> otherParameters) {
  User? _user = FirebaseAuth.instance.currentUser;

  // Create the call event data (without the 'callType' field)
  Map<String, dynamic> callData = {
    'sentAt': Timestamp.now(),  // The timestamp when the call was made
    'senderId': _user!.uid,     // The sender's user ID
    'receiverId': widget.otherUserId, // The receiver's user ID
    'seenBySender': true,       // Whether the sender has seen the call event
    'seenByReceiver': false,    // Whether the receiver has seen the call event
  };

  // Create a new document in the 'calls' collection
  FirebaseFirestore.instance.collection('calls').add(callData).then((docRef) {
    print('Call event logged successfully.');

    _sendNotification(widget.otherUserId, 'Call');

    // Reference to the chat document
    DocumentReference chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // Check if the chat document exists
    chatDoc.get().then((docSnapshot) {
      if (!docSnapshot.exists) {
        // If the document does not exist, create it
        chatDoc.set({
          'lastMessageAt': Timestamp.now(),
          'participants': [_user!.uid, widget.otherUserId], // Set the 'lastMessageAt' field
        }).then((value) {
          print("Chat document created successfully.");
        }).catchError((error) {
          print("Failed to create chat document: $error");
        });
      } else {
        // If the document exists, update it
        chatDoc.update({
          'lastMessageAt': Timestamp.now(),  // Update 'lastMessageAt'
        }).then((value) {
          print("'lastMessageAt' updated successfully.");
        }).catchError((error) {
          print("Failed to update 'lastMessageAt': $error");
        });
      }
    }).catchError((error) {
      print("Error checking chat document: $error");
    });
  }).catchError((error) {
    print('Failed to log call event: $error');
  });
}




  void _sendMessage() async {
    User? _user = FirebaseAuth.instance.currentUser;
    String message = _messageController.text.trim();

    if (message.isNotEmpty) {
      Map<String, dynamic> messageData = {
        'text': message,
        'sentAt': Timestamp.now(),
        'senderId': _user!.uid,
        'receiverId': widget.otherUserId,
        'seenBySender': true,
        'seenByReceiver': false,
      };

      Map<String, dynamic> chatData = {
        'participants': [_user.uid, widget.otherUserId],
        'lastMessageAt': Timestamp.now(),
      };

      DocumentReference chatDoc =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      chatDoc.set(chatData, SetOptions(merge: true));

      chatDoc.collection('messages').add(messageData).then((value) {
        print('Message sent successfully.');
        // Send a notification to the receiver
        _sendNotification(widget.otherUserId, message);
      }).catchError((error) {
        print('Failed to send message: $error');
      });

      _messageController.clear();
    } else {
      print('Message is empty.');
    }
  }

  void _sendNotification(String receiverId, String message) async {
    // Get the receiver's token
    DocumentSnapshot tokenDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .get();
    if (tokenDoc.exists &&
        (tokenDoc.data() as Map<String, dynamic>).containsKey('token')) {
      String receiverToken = (tokenDoc.data() as Map<String, dynamic>)['token'];

      // Send a message to the receiver's device
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAA7zIfwHI:APA91bEC1rJkBiotOso3HIrhZNJy-AAdNIxpUST7X2KN8sbZrWMggrK-Tbe_UBDnE1Xk8bcDW9Yz_P0znWtQcbInJDsbKnk9U-oWL5bWK0JZYHx-CxPcbQL8xOh_dj0VShazZnUAcuOk',
        },
        body: jsonEncode(
          {
            'notification': {
              'title': 'New Message',
              'body': message,
            },
            'priority': 'high',
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
            },
            'to': receiverToken,
          },
        ),
      );

      FlutterAppBadger.updateBadgeCount(1);
    } else {
      print('Token not found for user: $receiverId');
    }
  }
  void _showDeleteMessageDialog(DocumentSnapshot messageDoc) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final String messageSenderId = messageDoc['senderId'];

    if (currentUserId == messageSenderId) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Image.asset(
              constants.logoPath,
              height: 100,
              width: 100,
            ),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Wanna delete?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              GestureDetector(
                onTap: () {
                  messageDoc.reference.delete();
                  Navigator.of(context).pop();
                },
                child: Container(
                  height: 45,
                  width: 90,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.yes,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFE29100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}
