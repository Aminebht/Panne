import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallPage extends StatelessWidget {
  const CallPage(
      {Key? key,
      required this.callID,
      required this.userID,
      required this.userName})
      : super(key: key);
  final String callID;
  final String userID;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return ZegoSendCallInvitationButton(
      isVideoCall: false,
      resourceID:
          "panne_auto", //You need to use the resourceID that you created in the subsequent steps. Please continue reading this document.
      invitees: [
        ZegoUIKitUser(
          id: userID,
          name: userName,
        ),
      ],
    );
  }
}
