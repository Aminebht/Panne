import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:panne_auto/constants.dart';
import 'package:panne_auto/pages/about_us.dart';
import 'package:panne_auto/pages/client%20pages/CustomSearchDelegate.dart';
import 'package:panne_auto/pages/client%20pages/jobs_page.dart';
import 'package:panne_auto/pages/login_page.dart';
import 'package:panne_auto/pages/user_condition.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key = const Key('')}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

Future<void> deleteAccount() async {
  User? user = FirebaseAuth.instance.currentUser;

  // Delete user data from Firestore
  await FirebaseFirestore.instance.collection('users').doc(user?.uid).delete();

  // Delete user from Firebase Authentication
  await user?.delete();

  // Sign out
}

void _showLanguageSelection(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        child: Wrap(
          children: <Widget>[
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.select_language,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
            _buildLanguageOption(
                context, AppLocalizations.of(context)!.english, Locale('en')),
            _buildLanguageOption(
                context, AppLocalizations.of(context)!.french, Locale('fr')),
            _buildLanguageOption(
                context, AppLocalizations.of(context)!.arabic, Locale('ar')),
          ],
        ),
      );
    },
  );
}

// Shuffle the list of jobs randomly

Widget _buildLanguageOption(
    BuildContext context, String languageName, Locale locale) {
  return ListTile(
    title: Text(languageName),
    onTap: () {
      MyApp.changeLanguage(context, locale);
      Navigator.of(context).pop(); // Close the language selection bottom sheet
    },
  );
}

class _HomePageState extends State<HomePage> {
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initBannerAd();
  }

  _initBannerAd() {
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: 'ca-app-pub-1710240061961493/9424285915',
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
          });
          print('Ad failed to load: ${error.message}');
        },
      ),
      request: const AdRequest(),
    );
    _bannerAd.load();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> jobs = [
      {
        "category": "Mechanic",
        "localizationKey": AppLocalizations.of(context)!.mechanic,
        "iconPath": "assets/icons/Engine problems.png"
      },
      {
        "category": "Car wash",
        "localizationKey": AppLocalizations.of(context)!.car_wash,
        "iconPath": "assets/icons/Foam.png"
      },
      {
        "category": "Car check",
        "localizationKey": AppLocalizations.of(context)!.car_check,
        "iconPath": "assets/icons/Checklist.png"
      },
      {
        "category": "Car rent",
        "localizationKey": AppLocalizations.of(context)!.car_rent,
        "iconPath": "assets/logos/car-key 1.png"
      },
      {
        "category": "Ambulance",
        "localizationKey": AppLocalizations.of(context)!.ambulance,
        "iconPath": "assets/logos/ambulace 1.png"
      },
      {
        "category": "Electricite auto",
        "localizationKey": AppLocalizations.of(context)!.electrician,
        "iconPath": "assets/logos/lightning 1.png"
      },
      {
        "category": "SoS remorquage",
        "localizationKey": AppLocalizations.of(context)!.sos_remorquage,
        "iconPath": "assets/icons/tow.png"
      },
      {
        "category": "Car Driver",
        "localizationKey": AppLocalizations.of(context)!.taxi,
        "iconPath": "assets/icons/driver.png"
      },
      {
        "category": "Delivery",
        "localizationKey": AppLocalizations.of(context)!.livreur,
        "iconPath": "assets/icons/fast-delivery.png"
      },
      {
        "category": "Tire Repair",
        "localizationKey": AppLocalizations.of(context)!.pneu,
        "iconPath": "assets/icons/wheel.png"
      },
      {
        "category": "Car Charger",
        "localizationKey": AppLocalizations.of(context)!.bornes_electiques,
        "iconPath": "assets/icons/icons8-car-charger-96.png"
      },
      {
        "category": "Car Windows",
        "localizationKey":
            AppLocalizations.of(context)!.window,
        "iconPath": "assets/icons/maintenance.png"
      },
    ];
    jobs.shuffle();
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                      child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Image.asset(
                      constants.logoPath,
                    ),
                  )),
                  ListTile(
                    title: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AboutUsPage(),
                          ),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.about_us,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ListTile(
                    title: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UserConditions(),
                          ),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.user_conditions,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ListTile(
                    title: GestureDetector(
                      onTap: () {
                        _showLanguageSelection(context);
                      },
                      child: Text(
                        AppLocalizations.of(context)!.change_language,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.delete_account,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: SizedBox(
                              height: 50.0, // Adjust height as needed
                              width: 50.0,
                              child: Image.asset(
                                constants.logoPath,
                              ),
                            ),
                            content: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.sur,
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
                                  deleteAccount();
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => LoginPage(),
                                    ),
                                  );
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
                                ).animate().shake(),
                              )
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              child: Align(
                alignment: FractionalOffset.bottomCenter,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.contact_us,
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              child: Text(
                                '0021653891010',
                                style: GoogleFonts.poppins(),
                              ),
                              onTap: () {
                                launch('tel:0021653891010');
                              },
                            ),
                            GestureDetector(
                              child: Text(
                                'alayadigitalpro@gmail.com',
                                style: GoogleFonts.poppins(),
                              ),
                              onTap: () {
                                launch('mailto:alayadigitalpro@gmail.com');
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                    // Add more ListTiles here...
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: size.height * 0.2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 40, left: 20, right: 20),
                    child: Builder(builder: (BuildContext context) {
                      return GestureDetector(
                          onTap: () {
                            Scaffold.of(context).openDrawer();
                          },
                          child: Image.asset(
                            constants.logoPath,
                            height: 50,
                            width: 50,
                          ).animate().scale().then().shake());
                    }),
                  ),
                ],
              ),
            ),
            Container(
              height: size.height * 0.25,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Image.asset(
                        'assets/icons/almost-done-mechanic-holding-tire-repair-garage-replacement-winter-summer-tires 1.png')
                    .animate()
                    .fadeIn(),
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 50, right: 45),
                  child: Text(
                    AppLocalizations.of(context)!.looking,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
              ],
            ),
            Column(
              children: jobs.map((job) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20, left: 45, right: 45),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return JobsPage(
                          category: job["category"]!,
                        );
                      }));
                    },
                    child: Container(
                      height: 62,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                truncateText('${job["localizationKey"]!}',
                                    25 // Change this value to your desired maximum length
                                    ),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Image.asset(
                              job["iconPath"]!,
                              height: 28,
                            )
                          ],
                        ),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF235A81),
                            Color(0xFFE29100),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ).animate().slideX().then().shimmer(),
                  ),
                );
              }).toList(),
            ),
            if (_isAdLoaded)
              Container(
                height: _bannerAd.size.height.toDouble(),
                width: _bannerAd.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd),
              ),
          ],
        ),
      ),
    );
  }
}

String truncateText(String text, int maxLength) {
  if (text.length <= maxLength) {
    return text;
  } else {
    return '${text.substring(0, maxLength)}...';
  }
}
