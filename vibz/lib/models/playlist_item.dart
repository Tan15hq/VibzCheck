import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistItem {
  final String id; // Firestore doc ID
  final String trackId;

  // Spotify metadata
  final String title;
  final List<String> artists;
  final int durationMs;
  final String? previewUrl;
  final String? artwork;

  // State
  final String addedBy;
  final DateTime addedAt;
  final Map<String, int> votes; // { uid: +1 | -1 }
  final int voteScore;
  final String status; // queued | playing | played
  final Map<String, dynamic>? mood;

  PlaylistItem({
    required this.id,
    required this.trackId,
    required this.title,
    required this.artists,
    required this.durationMs,
    required this.addedBy,
    required this.addedAt,
    required this.votes,
    required this.voteScore,
    required this.status,
    this.previewUrl,
    this.artwork,
    this.mood,
  });

  /* ---------- FROM FIRESTORE ---------- */

  factory PlaylistItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
    
    return PlaylistItem(
      id: doc.id,
      trackId: data['trackId'] ?? '',
      title: metadata['title'] ?? '',
      artists: List<String>.from(metadata['artists'] ?? []),
      durationMs: metadata['duration_ms'] ?? 0,
      previewUrl: metadata['preview_url'],
      artwork: metadata['artwork'],
      addedBy: data['addedBy'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0),
      votes: Map<String, int>.from(data['votes'] ?? {}),
      voteScore: data['voteScore'] ?? 0,
      status: data['status'] ?? 'queued',
      mood: data['mood'] as Map<String, dynamic>?,
    );
  }

  /* ---------- TO FIRESTORE ---------- */

  Map<String, dynamic> toMap() {
    return {
      'trackId': trackId,
      'addedBy': addedBy,
      'addedAt': Timestamp.fromDate(addedAt),
      'status': status,
      'votes': votes,
      'voteScore': voteScore,
      'metadata': {
        'title': title,
        'artists': artists,
        'duration_ms': durationMs,
        'preview_url': previewUrl,
        'artwork': artwork,
        'mood': mood,

      },
    };
  }
}
