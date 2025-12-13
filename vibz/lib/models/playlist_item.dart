// playlist_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistItem {
  final String itemId;
  final String trackId;
  final String title;
  final List<String> artists;
  final int durationMs;
  final String? previewUrl;
  final String? artwork;
  final String addedBy;
  final Timestamp addedAt;
  final Map<String, dynamic> votes; // { 'up': int, 'down': int }
  final String status;

  PlaylistItem({
    required this.itemId,
    required this.trackId,
    required this.title,
    required this.artists,
    required this.durationMs,
    required this.addedBy,
    required this.addedAt,
    required this.votes,
    required this.status,
    this.previewUrl,
    this.artwork,
  });

  factory PlaylistItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlaylistItem(
      itemId: data['itemId'] ?? doc.id,
      trackId: data['trackId'] ?? '',
      title: (data['metadata']?['title'] ?? '') as String,
      artists: List<String>.from((data['metadata']?['artists'] ?? []) as List<dynamic>),
      durationMs: (data['metadata']?['duration_ms'] ?? 0) as int,
      previewUrl: data['metadata']?['preview_url'] as String?,
      artwork: data['metadata']?['artwork'] as String?,
      addedBy: data['addedBy'] ?? '',
      addedAt: data['addedAt'] ?? Timestamp.now(),
      votes: Map<String, dynamic>.from(data['votes'] ?? {'up': 0, 'down': 0}),
      status: data['status'] ?? 'queued',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'trackId': trackId,
      'addedBy': addedBy,
      'addedAt': addedAt,
      'status': status,
      'metadata': {
        'title': title,
        'artists': artists,
        'duration_ms': durationMs,
        'preview_url': previewUrl,
        'artwork': artwork,
      },
      'votes': votes,
    };
  }
}
