import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String text;
  final String sentBy;
  final String senderName;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sentBy,
    required this.senderName,
    required this.sentAt,
  });

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      sentBy: data['sentBy'] ?? '',
      senderName: data['senderName'] ?? 'User',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sentBy': sentBy,
      'senderName': senderName,
      'sentAt': FieldValue.serverTimestamp(),
    };
  }
}
