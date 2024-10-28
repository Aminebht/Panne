import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panne_auto/componant/artisan_bottom_navbar.dart';
import 'package:panne_auto/componant/button_navbar.dart';
import 'package:panne_auto/componant/spinning_img.dart';

import 'package:panne_auto/pages/getstarted_screen.dart';

import 'package:panne_auto/providers/auth_providers.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage>
    with WidgetsBindingObserver {
  bool shouldResetBadge = false;
  @override
  void initState() {
    super.initState();
    initZego();
    WidgetsBinding.instance.addObserver(this); // Add the observer
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove the observer
    super.dispose();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Check if badge reset is necessary based on your criteria
      if (shouldResetBadge) {
        try {
          // Attempt to reset the badge count
          FlutterAppBadger.updateBadgeCount(0);
        } catch (error) {
          // Handle potential errors during badge update (e.g., logging, user notification)
          print("Error resetting badge: $error");
        }
        // Reset the flag (optional, depending on your resetting logic)
        shouldResetBadge = false;
      }
    }
  }

  Future<void> initZego() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userSnapshot.exists) {
        String name = userSnapshot['fullName'];
        ZegoUIKitPrebuiltCallInvitationService().init(
          appID: 312542080 /*input your AppID*/,
          appSign:
              '802ecb8248d6db0dcdbd071a1eed951a85c43c79128f8ef263679425b591700d' /*input your AppSign*/,
          userID: user.uid,
          userName: name,
          plugins: [ZegoUIKitSignalingPlugin()],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: ref.watch(firebaseAuthProvider).authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            User? user = snapshot.data;
            return ref.watch(userTypeProvider(user!.uid)).when(
                  data: (userType) {
                    if (userType != null) {
                      if (userType == 'Client') {
                        return CustomNavBar();
                      } else if (userType == 'Artisan') {
                        return ArtisanNavbar();
                      } else {
                        // Handle other user types or scenarios
                        return GetStaredScreen();
                      }
                    } else {
                      // Handle case where user type is null
                      return GetStaredScreen();
                    }
                  },
                  loading: () => Center(child: SpinningImage()),
                  error: (err, stack) => Text('Error: $err'),
                );
          } else {
            return GetStaredScreen();
          }
        },
      ),
    );
  }
}
