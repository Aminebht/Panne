import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panne_auto/componant/AdMob.dart';
import 'package:panne_auto/componant/button.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:panne_auto/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:panne_auto/pages/about_us.dart';
import 'package:panne_auto/pages/login_page.dart';
import 'package:panne_auto/pages/user_condition.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../providers/auth_providers.dart';
import 'package:panne_auto/pages/artisan_page/subscription.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ArtisanPage extends ConsumerStatefulWidget {
  const ArtisanPage({super.key});

  @override
  createState() => _ArtisanPageState();
}

class _ArtisanPageState extends ConsumerState<ArtisanPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _descriptionController = TextEditingController();
  User? user;
  DocumentSnapshot? userData;
  bool _isLoading = false;
  bool isFirstTimeActivatingLocation = true;

  Future<void> deleteAccount() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      // Delete all jobs for the current user
      CollectionReference jobs = FirebaseFirestore.instance.collection('jobs');

      // Get all job documents for the current user
      QuerySnapshot jobSnapshot =
          await jobs.where('user id', isEqualTo: userId).get();

      // Delete each job document and associated likes
      for (QueryDocumentSnapshot job in jobSnapshot.docs) {
        String jobId = job.id;

        // Delete all likes for the current job
        CollectionReference likes =
            FirebaseFirestore.instance.collection('likes');

        // Get all like documents for the current job
        QuerySnapshot likeSnapshot =
            await likes.where('job id', isEqualTo: jobId).get();

        // Delete each like document
        for (QueryDocumentSnapshot like in likeSnapshot.docs) {
          await likes.doc(like.id).delete();
        }

        // Delete the job document
        await jobs.doc(jobId).delete();
      }

      // Delete user data from Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // Delete user from Firebase Authentication
      await user.delete();

      // Sign out
    }
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

  Widget _buildLanguageOption(
      BuildContext context, String languageName, Locale locale) {
    return ListTile(
      title: Text(languageName),
      onTap: () {
        MyApp.changeLanguage(context, locale);
        Navigator.of(context)
            .pop(); // Close the language selection bottom sheet
      },
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String dropdownValue = "";
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    DrawerHeader(
                        child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Image.asset(constants.logoPath),
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
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
                              title: Image.asset(
                                constants.logoPath,
                                height: 50,
                                width: 50,
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
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold),
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
        body: Column(
          children: [
            Container(
              height: size.height * 0.2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 40,
                    ),
                    child: Builder(builder: (BuildContext context) {
                      return GestureDetector(
                          onTap: () {
                            Scaffold.of(context).openDrawer();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20, left: 20),
                            child: Image.asset(
                              constants.logoPath,
                              height: 50,
                              width: 50,
                            ).animate().scale().then().shake(),
                          ));
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
                      .fadeIn()),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 50, right: 50),
                  child: Text(
                    AppLocalizations.of(context)!.add_job,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 70),
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder:
                            (BuildContext context, StateSetter setModalState) {
                          return Container(
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: Scaffold(
                              body: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.add_job,
                                          // Add your text style here (e.g., GoogleFonts.poppins)
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 40,
                                  ),
                                  Container(
                                    height: 58,
                                    width: 303,
                                    child: PopupMenuButton<String>(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              dropdownValue,
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Icon(Icons.arrow_downward),
                                          ],
                                        ),
                                      ),
                                      onSelected: (String value) {
                                        setModalState(() {
                                          dropdownValue = value;
                                        });
                                        print('Selected value: $value');
                                        print('Selected value: $dropdownValue');
                                      },
                                      itemBuilder: (BuildContext context) {
                                        final applocalization =
                                            AppLocalizations.of(context)!;
                                        return <PopupMenuEntry<String>>[
                                          PopupMenuItem<String>(
                                            value: 'Mechanic',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons.build),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 50,
                                                      vertical: 8),
                                                  child: Text(
                                                      applocalization.mechanic),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Car wash',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons.soap),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 50,
                                                      vertical: 8),
                                                  child: Text(
                                                      applocalization.car_wash),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Car check',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons.car_repair),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 50,
                                                      vertical: 8),
                                                  child: Center(
                                                      child: Text(
                                                          applocalization
                                                              .car_check)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Car rent',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons.car_rental),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 50,
                                                      vertical: 8),
                                                  child: Center(
                                                      child: Text(
                                                          applocalization
                                                              .car_rent)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Ambulance',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons.healing),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 50,
                                                      vertical: 8),
                                                  child: Text(
                                                    applocalization.ambulance,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Electricite auto',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons.electric_bolt),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 50,
                                                      vertical: 8),
                                                  child: Text(
                                                    applocalization.electrician,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'SoS remorquage',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons.sos),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 50,
                                                      vertical: 8),
                                                  child: Text(
                                                    applocalization
                                                        .sos_remorquage,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Car Driver',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons.local_taxi),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 50,
                                                      vertical: 8),
                                                  child: Text(
                                                    applocalization.taxi,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Delivery',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons
                                                    .delivery_dining_rounded),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 50,
                                                      vertical: 8),
                                                  child: Text(
                                                    applocalization.livreur,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Tire Repair',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons.tire_repair),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 50,
                                                      vertical: 8),
                                                  child: Text(
                                                    applocalization.pneu,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Car Charger',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons.electric_car),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 50,
                                                      vertical: 8),
                                                  child: Text(applocalization
                                                      .bornes_electiques),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Electric car repairs',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons.car_repair_outlined),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 50,
                                                      vertical: 8),
                                                  child: Text(truncateText(
                                                    applocalization
                                                        .reparation_automobile_electrique,
                                                    25, // Adjust maxLength as needed
                                                  )),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ];
                                      },
                                    ).animate().shake(),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFD9D9D9),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 50),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!
                                              .description,
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 50),
                                    child: TextField(
                                      controller: _descriptionController,
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context)!
                                            .write_here,
                                        hintStyle: GoogleFonts.poppins(
                                            color: Color(0xFF000000)
                                                .withOpacity(0.4),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                          borderSide: BorderSide(
                                            color: Color(0xFF235A81),
                                            width: 3.0,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                          borderSide: BorderSide(
                                            color: Color(0xFF235A81),
                                            width: 3.0,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 15.0,
                                            horizontal:
                                                16.0), // Adjust height and left spacing
                                        isDense: true,
                                      ),
                                      maxLines: null,
                                      minLines: 5,
                                    ),
                                  ),
                                  Spacer(),
                                  // In your widget:
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 30),
                                    child:GestureDetector(
                                              onTap: () async {
                                                User? _user = ref.read(firebaseAuthProvider).currentUser;

                                                if (_user != null) {
                                                  // Fetch job details to check for duplicates
                                                  var jobSnapshot = await ref
                                                      .read(firebaseFirestoreProvider)
                                                      .collection('jobs')
                                                      .where('user id', isEqualTo: _user.uid)
                                                      .where('job type', isEqualTo: dropdownValue)
                                                      .get();

                                                  if (jobSnapshot.docs.isNotEmpty) {
                                                    // Show toast if job of this type already exists
                                                    Fluttertoast.showToast(
                                                      msg: "You already have a job of this type.",
                                                      toastLength: Toast.LENGTH_SHORT,
                                                      gravity: ToastGravity.BOTTOM,
                                                      backgroundColor: Colors.red,
                                                      textColor: Colors.white,
                                                    );
                                                    _descriptionController.clear();
                                                  } else {
                                                    // Navigate to Subscription page if no duplicate job is found
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => SubscriptionScreen(DropdownValue: dropdownValue),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              child: _isLoading ? SpinningImage() : MainButton(
                                                name: AppLocalizations.of(context)!.add_job,
                                              ),
                                            ),

                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                child: Container(
                  height: 120,
                  width: 317,
                  child: Icon(
                    FeatherIcons.plus,
                    color: Colors.black,
                    size: 35,
                  ),
                  decoration: BoxDecoration(
                      color: Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(30)),
                )
                    .animate()
                    .slideX(duration: Duration(milliseconds: 200))
                    .then()
                    .shimmer(),
              ),
            ),
            Spacer(),
            AdBanner(),
          ],
        ));
  }
}

String truncateText(String text, int maxLength) {
  if (text.length <= maxLength) {
    return text; // Return the original text if it's not longer than maxLength
  } else {
    return '${text.substring(0, maxLength)}...'; // Truncate and add ellipsis
  }
}
