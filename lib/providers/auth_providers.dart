import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firebaseFirestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final userTypeProvider =
    FutureProvider.family<String?, String>((ref, userId) async {
  DocumentSnapshot userSnapshot = await ref
      .read(firebaseFirestoreProvider)
      .collection('users')
      .doc(userId)
      .get();

  if (userSnapshot.exists) {
    return userSnapshot['user type'];
  } else {
    return null;
  }
});
