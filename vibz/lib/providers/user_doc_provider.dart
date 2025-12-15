import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final userDocProvider = StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>(
  (ref, uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots();
  },
);
