// firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
    final FirebaseFirestore _db = FirebaseFirestore.instance;

    /// Add a playlist item to room (client-side metadata)
    Future<void> addPlaylistItem({
    required String roomId,
    required String trackId,
    required String title,
    required List<String> artists,
    required int durationMs,
    String? previewUrl,
    String? artwork,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final itemId = '${trackId}_${DateTime.now().millisecondsSinceEpoch}';

    final docRef = _db
        .collection('rooms')
        .doc(roomId)
        .collection('playlist')
        .doc(itemId);

    final payload = {
      'itemId': itemId,
      'trackId': trackId,
      'addedBy': uid,
      'addedAt': FieldValue.serverTimestamp(),
      'status': 'queued',
      'metadata': {
        'title': title,
        'artists': artists,
        'duration_ms': durationMs,
        'preview_url': previewUrl,
        'artwork': artwork,
      },
      'votes': {'up': 0, 'down': 0},
    };

    await docRef.set(payload);
  }


  /// Create or update a user's vote document: id = "{uid}_{itemId}"
  Future<void> setVote({
    required String roomId,
    required String itemId,
    required String vote, // 'up' or 'down' or 'none'
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final voteDocId = '${uid}_$itemId';
    final voteRef = _db.collection('rooms').doc(roomId).collection('votes').doc(voteDocId);

    if (vote == 'none') {
      // delete vote
      await voteRef.delete().catchError((_) {});
      return;
    }

    await voteRef.set({
      'userId': uid,
      'itemId': itemId,
      'vote': vote,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<DocumentSnapshot>> playlistStream(String roomId) {
    return _db.collection('rooms').doc(roomId).collection('playlist')
      .orderBy('addedAt', descending: false)
      .snapshots()
      .map((snap) => snap.docs);
  }

  Stream<DocumentSnapshot> roomDocStream(String roomId) {
    return _db.collection('rooms').doc(roomId).snapshots();
  }

  Stream<QuerySnapshot> votesForRoom(String roomId) {
    return _db.collection('rooms').doc(roomId).collection('votes').snapshots();
  }
}
