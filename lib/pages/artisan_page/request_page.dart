import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:panne_auto/providers/auth_providers.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RequestPage extends ConsumerStatefulWidget {
  const RequestPage({super.key});

  @override
  createState() => _RequestPageState();
}

class _RequestPageState extends ConsumerState<RequestPage> {
  String? _userId;
  Stream<QuerySnapshot> getUserJobs(String userId) {
    return ref
        .read(firebaseFirestoreProvider)
        .collection('jobs')
        .where('user id', isEqualTo: userId)
        .snapshots();
  }

  Future<void> deleteJob(String jobId) async {
    // Delete all likes for the current job
    CollectionReference likes = FirebaseFirestore.instance.collection('likes');

    // Get all like documents for the current job
    QuerySnapshot likeSnapshot =
        await likes.where('job id', isEqualTo: jobId).get();

    // Delete each like document
    for (QueryDocumentSnapshot like in likeSnapshot.docs) {
      await likes.doc(like.id).delete();
    }

    // Delete the job document
    await ref
        .read(firebaseFirestoreProvider)
        .collection('jobs')
        .doc(jobId)
        .delete();
  }

  @override
  void initState() {
    super.initState();
    final _user = ref.read(firebaseAuthProvider).currentUser;
    _userId = _user?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: Text(
              AppLocalizations.of(context)!.your_jobs,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 24),
            ).animate().shimmer(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getUserJobs(_userId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: SpinningImage());
                }

                return ListView(
                  children:
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
                        data['job type'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
      if (data['expiry date'] != null)
      Text(
        AppLocalizations.of(context)!.expiry+' ${DateFormat('yyyy-MM-dd').format((data['expiry date'] as Timestamp).toDate())}',
        style: TextStyle(color: Colors.grey),
      ),
    ],
  ),
                      
  subtitle: Text(data['description']),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      IconButton(
        icon: Icon(
          Icons.delete,
          color: Colors.red[300],
        ).animate().shake(),
        onPressed: () async {
                              // Delete the job
                              deleteJob(document.id);
        },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ).animate().slideX(duration: Duration(milliseconds: 150));
              },
            ),
          ),
        ],
      ),
    );
  }
}
