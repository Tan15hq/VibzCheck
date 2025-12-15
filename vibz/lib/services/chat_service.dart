import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  Future<void> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    if (text.trim().isEmpty) return;

    await _db
        .collection('rooms')
        .doc(roomId)
        .collection('chat')
        .add({
      'text': text.trim(),
      'sentBy': user.uid,
      'senderName': user.displayName ?? 'User',
      'sentAt': FieldValue.serverTimestamp(),
    });
  }
}
