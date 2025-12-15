import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'spotify_audio_features_service.dart';
import 'spotify_service.dart';

class PlaylistService {
  final _db = FirebaseFirestore.instance;

  Future<void> addTrack({
    required String roomId,
    required Map<String, dynamic> track,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final itemId =
        '${track['trackId']}_${DateTime.now().millisecondsSinceEpoch}';

    final spotify = SpotifyService();
    final moodSvc = SpotifyAudioFeaturesService(spotify);

    Map<String, dynamic>? mood;
    try {
      mood = await moodSvc.fetchMood(track['trackId']);
    } catch (_) {}

    await _db
        .collection('rooms')
        .doc(roomId)
        .collection('playlist')
        .doc(itemId)
        .set({
      'trackId': track['trackId'],
      'addedBy': uid,
      'addedAt': FieldValue.serverTimestamp(),
      'status': 'queued',
      'votes': {},
      'voteScore': 0,
      'metadata': {
        'title': track['title'],
        'artists': track['artists'],
        'duration_ms': track['durationMs'],
        'preview_url': track['previewUrl'],
        'artwork': track['artwork'],
      },
      'mood': mood,
    });
  }

}
