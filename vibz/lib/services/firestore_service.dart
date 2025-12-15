import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --------------------------------------------------
  // PLAYLIST
  // --------------------------------------------------

  /// Add a playlist item to a room
  Future<void> addPlaylistItem({
    required String roomId,
    required String trackId,
    required String title,
    required List<String> artists,
    required int durationMs,
    String? previewUrl,
    String? artwork,
    Map<String, dynamic>? mood,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final itemId = '${trackId}_${DateTime.now().millisecondsSinceEpoch}';

    final docRef = _db
        .collection('rooms')
        .doc(roomId)
        .collection('playlist')
        .doc(itemId);

    await docRef.set({
      'itemId': itemId,
      'trackId': trackId,
      'addedBy': uid,
      'addedAt': FieldValue.serverTimestamp(),
      'status': 'queued',

      // voting
      'votes': {},        // map<uid, "up" | "down">
      'voteScore': 0,     // computed by Cloud Function

      // metadata
      'metadata': {
        'title': title,
        'artists': artists,
        'duration_ms': durationMs,
        'preview_url': previewUrl,
        'artwork': artwork,
      },

      // optional mood data
      if (mood != null) 'mood': mood,
    });
  }

  /// Stream playlist items in deterministic order
  Stream<List<DocumentSnapshot>> playlistStream(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('playlist')
        .orderBy('voteScore', descending: true)
        .orderBy('addedAt')
        .snapshots()
        .map((snap) => snap.docs);
  }

  // --------------------------------------------------
  // VOTING (TRANSACTION SAFE)
  // --------------------------------------------------

  /// Set or remove a user's vote for a playlist item
  Future<void> setVote({
    required String roomId,
    required String itemId,
    required String vote, // 'up' | 'down' | 'none'
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
      final votes = Map<String, dynamic>.from(data['votes'] ?? {});

      if (vote == 'none') {
        votes.remove(uid);
      } else {
        votes[uid] = vote;
      }

      tx.update(ref, {'votes': votes});
    });
  }

  // --------------------------------------------------
  // ROOM
  // --------------------------------------------------

  /// Stream room document
  Stream<DocumentSnapshot> roomDocStream(String roomId) {
    return _db.collection('rooms').doc(roomId).snapshots();
  }
}
