import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Future<void> deleteExpiredJobs() async {
  final today = DateTime.now();
  final formattedToday = DateFormat('yyyy-MM-dd').format(today);

  try {
    // Step 1: Query the jobs collection to find expired jobs
    final jobSnapshot = await FirebaseFirestore.instance.collection('jobs').get();

    for (var job in jobSnapshot.docs) {
      // Log job details for troubleshooting
      print("Checking job with ID: ${job.id}");

      if (job.data().containsKey('expiry date')) {
        DateTime expiryDate = (job['expiry date'] as Timestamp).toDate();
        String formattedExpiryDate = DateFormat('yyyy-MM-dd').format(expiryDate);

        // Check if the expiry date matches today's date
        if (formattedExpiryDate == formattedToday) {
          print("Found expired job with ID: ${job.id}");

          // Step 2: Get the job id of the expired job
          String jobId = job.id;

          // Step 3: Delete documents in another collection with matching job id
          await FirebaseFirestore.instance
              .collection('likes') // Replace with your actual collection name
              .where('job id', isEqualTo: jobId)
              .get()
              .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.delete();
              print('Deleted document in related collection with job id: $jobId');
            }
          });

          // Also delete the job document itself in the 'jobs' collection
          await job.reference.delete();
          print('Deleted job document in "jobs" collection with ID: ${job.id}');
        } else {
          print("Job with ID: ${job.id} is not expired today.");
        }
      } else {
        print("Job with ID: ${job.id} has no expiry date.");
      }
    }
  } catch (e) {
    print("Error deleting expired jobs: $e");
  }
}
