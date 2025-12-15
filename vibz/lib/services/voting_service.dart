import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VotingService {
  final _db = FirebaseFirestore.instance;

  Future<void> voteOnTrack({
    required String roomId,
    required String itemId,
    required int vote, // +1 or -1
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final ref = _db
        .collection('rooms')
        .doc(roomId)
        .collection('playlist')
        .doc(itemId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final Map<String, dynamic> votes =
          Map<String, dynamic>.from(data['votes'] ?? {});

      final int previousVote = votes[uid] ?? 0;

      int score = (data['voteScore'] ?? 0) - previousVote;

      votes[uid] = vote;
      score += vote;

      tx.update(ref, {
        'votes': votes,
        'voteScore': score,
      });
    });
  }
}
