import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:panne_auto/componant/AdMob.dart';
import 'package:panne_auto/componant/button.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:panne_auto/constants.dart';
import 'package:panne_auto/pages/about_us.dart';
import 'package:panne_auto/pages/login_page.dart';
import 'package:panne_auto/pages/user_condition.dart';
import 'package:panne_auto/providers/auth_providers.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../main.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _fullnameController = TextEditingController();
  final _phoneController = TextEditingController();
  User? user;
  DocumentSnapshot? userData;
  bool _isUploading = false;
  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadPic() async {
    // Get the file from the image picker and store it
    final ImagePicker _picker = ImagePicker();
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    // Create a reference to the location you want to upload to in firebase
    Reference reference =
        _storage.ref().child("images/${DateTime.now().toString()}");

    // Upload the file to firebase
    UploadTask uploadTask = reference.putFile(File(image!.path));

    // Waits till the file is uploaded then stores the download url
    TaskSnapshot snapshot = await uploadTask;
    String location = await snapshot.ref.getDownloadURL();

    // Returns the download url
    return location;
  }

  Future<void> uploadUserProfilePic() async {
    setState(() {
      _isUploading = true;
    });

    try {
      String imageUrl = await uploadPic(); // Use the updated uploadPic function

      String userId = ref.read(firebaseAuthProvider).currentUser!.uid;
      await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(userId)
          .update({
        'image url': imageUrl, // imageUrl is now a String
      });
      await ref
          .read(firebaseFirestoreProvider)
          .collection('jobs')
          .where('user id', isEqualTo: userId)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.update({'image url': imageUrl});
        });
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
    fetchUserData();
  }

  fetchUserData() async {
    User? _user = ref.read(firebaseAuthProvider).currentUser;
    DocumentSnapshot _userData = await ref
        .read(firebaseFirestoreProvider)
        .collection('users')
        .doc(_user!.uid)
        .get();
    setState(() {
      user = _user;
      userData = _userData;
    });
  }

  void update() async {
    User? _user = ref.read(firebaseAuthProvider).currentUser;
    Map<String, dynamic> dataToUpdate = {};
    Map<String, dynamic> jobDataToUpdate = {};

    if (_fullnameController.text.trim().isNotEmpty) {
      dataToUpdate['fullName'] = _fullnameController.text.trim();
      jobDataToUpdate['user name'] =
          _fullnameController.text.trim(); // Update 'user name' in 'jobs'
    }

    if (_phoneController.text.trim().isNotEmpty) {
      dataToUpdate['phone'] = _phoneController.text.trim();
      jobDataToUpdate['phone number'] =
          _phoneController.text.trim(); // Update 'phone number' in 'jobs'
    }

    if (dataToUpdate.isNotEmpty) {
      await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(_user?.uid)
          .update(dataToUpdate);
      await ref
          .read(firebaseFirestoreProvider)
          .collection('jobs')
          .where('user id', isEqualTo: _user?.uid)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference
              .update(jobDataToUpdate); // Update 'jobs' with 'jobDataToUpdate'
        });
      });
      await fetchUserData();
    }
  }

  void signOut() async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'isOnline': false,
    });
    await ref.read(firebaseAuthProvider).signOut();
    ZegoUIKitPrebuiltCallInvitationService().uninit();
    // updateUserPresence(false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

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
    // Clean up the controller when the widget is disposed.
    _fullnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey =
        new GlobalKey<ScaffoldState>();
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
      body: (user != null && userData != null)
          ? Column(
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
                      Padding(
                        padding: const EdgeInsets.only(top: 30, right: 40),
                        child: ClipOval(
                          child: Image.network(
                            '${userData!['image url']}',
                            height: 100,
                            width: 100,
                          ).animate().shake(),
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.profile,
                      style: GoogleFonts.poppins(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Scaffold(
                                body: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)!
                                                .update,
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 24),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: 45, left: 45, top: 20),
                                      child: TextField(
                                        controller: _fullnameController,
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                        decoration: InputDecoration(
                                          hintText:
                                              AppLocalizations.of(context)!
                                                  .name,
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
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 45, right: 45, top: 32),
                                      child: TextField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                        decoration: InputDecoration(
                                          hintText:
                                              AppLocalizations.of(context)!
                                                  .phone,
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
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 55, vertical: 40),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)!
                                                .update_image,
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 24),
                                          ),
                                          GestureDetector(
                                            onTap: uploadUserProfilePic,
                                            child: Container(
                                              height: 60,
                                              width: 60,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: Image.asset(
                                                  'assets/icons/folder_upload.png',
                                                ),
                                              ),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF235A81),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    Spacer(),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 20),
                                      child: GestureDetector(
                                          onTap: () {
                                            update();
                                            Navigator.of(context).pop();
                                          },
                                          child: MainButton(
                                              name:
                                                  AppLocalizations.of(context)!
                                                      .update)),
                                    )
                                  ],
                                ),
                              );
                            });
                      },
                      child: Container(
                        width: 101,
                        height: 53,
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.edit,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Colors.white),
                          ),
                        ),
                        decoration: BoxDecoration(
                            color: Color(0xFF235A81),
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.name}:',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              '${userData!['fullName']}',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.phone}:',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              '${userData!['phone']}',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.email}:',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              '${user!.email}',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: GestureDetector(
                      onTap: () {
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
                                      AppLocalizations.of(context)!.sur,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24),
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
                                          fontSize: 18),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      signOut();
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
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                          color: Color(0xFFE29100),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ).animate().shake(),
                                  )
                                ],
                              );
                            });
                      },
                      child:
                          MainButton(name: AppLocalizations.of(context)!.logout)
                              .animate()
                              .shimmer()),
                ),
                AdBanner()
              ],
            )
          : Center(child: SpinningImage()),
    );
  }
}
