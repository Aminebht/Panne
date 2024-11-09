import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:panne_auto/auth/main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:panne_auto/functions/deleteExpiredJobs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 1.1.1 define a navigator key
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize();
  await deleteExpiredJobs();

  /// 1.1.2: set navigator key to ZegoUIKitPrebuiltCallInvitationService
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  // call the useSystemCallingUI
  ZegoUIKit().initLog().then((value) {
    ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
      [ZegoUIKitSignalingPlugin()],
    );

    runApp(ProviderScope(child: MyApp(navigatorKey: navigatorKey)));
  });
}
class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({
    required this.navigatorKey,
    Key? key,
  }) : super(key: key);

  static void changeLanguage(BuildContext context, Locale locale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(locale);
    _saveLocale(locale);
  }

  static Future<void> _saveLocale(Locale locale) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
  }

  static Future<String?> _getSavedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('language');
  }

  


  @override
  _MyAppState createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Locale _locale;
  late User _user;

  @override
  void initState() {
    super.initState();
    _locale = Locale('en'); // Initialize with a default value
    _loadSavedLocale();
    FlutterAppBadger.removeBadge();
    _initializeUser();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_user != null) {
      switch (state) {
        case AppLifecycleState.resumed:
          updateUserPresence(true); // Set user online when app is resumed
          break;
        case AppLifecycleState.paused:
          updateUserPresence(false); // Set user offline when app is paused
          break;
        default:
          break;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    if (_user != null) {
      updateUserPresence(false); // Set user offline when app is disposed
    }
    super.dispose();
  }

  void _initializeUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _user = user!;
        if (_user != null) {
          updateUserPresence(
              true); // Set user online when user is authenticated
        }
      });
    });
  }

  Future<void> updateUserPresence(bool isOnline) async {
    if (_user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .update({
        'isOnline': isOnline,
      }).then((_) {
        print('User presence updated successfully');
      }).catchError((error) {
        print('Failed to update user presence: $error');
      });
    }
  }

  Future<void> _loadSavedLocale() async {
    String? savedLocale = await MyApp._getSavedLocale();
    if (savedLocale != null) {
      setState(() {
        _locale = Locale(savedLocale);
      });
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /// 1.1.3: register the navigator key to MaterialApp
      navigatorKey: widget.navigatorKey,
      title: 'panne auto',
      color: Colors.white,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      locale: _locale,
      supportedLocales: [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
      ],
      home: MainPage(),
    );
  }
}
