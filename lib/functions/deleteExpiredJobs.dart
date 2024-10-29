import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Future<void> deleteExpiredJobs() async {
  final today = DateTime.now();
  final formattedToday = DateFormat('yyyy-MM-dd').format(today);

  try {
    // Step 1: Query the jobs collection to find expired jobs
    final jobSnapshot = await FirebaseFirestore.instance.collection('jobs').get();

    for (var job in jobSnapshot.docs) {
      if (job.data().containsKey('expiry date')) {
        DateTime expiryDate = (job['expiry date'] as Timestamp).toDate();
        String formattedExpiryDate = DateFormat('yyyy-MM-dd').format(expiryDate);

        if (formattedExpiryDate == formattedToday) {
          // Step 2: Get the job id of the expired job
          String jobId = job['job id'];

          // Step 3: Delete documents with matching job id
          await FirebaseFirestore.instance
              .collection('likes') // Replace with your actual collection name
              .where('job id', isEqualTo: jobId)
              .get()
              .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.delete();
              print('Deleted document with job id: $jobId');
            }
          });

          // Also delete the job document itself if needed
          await job.reference.delete();
          print('Deleted job document with ID: ${job.id}');
        }
      }
    }
  } catch (e) {
    print("Error deleting expired jobs: $e");
  }
}
