import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/colors.dart';
import '../../services/spotify_service.dart';

class SpotifySearchScreen extends StatefulWidget {
  final String roomId;
  const SpotifySearchScreen({super.key, required this.roomId});

  @override
  State<SpotifySearchScreen> createState() =>
      _SpotifySearchScreenState();
}

class _SpotifySearchScreenState extends State<SpotifySearchScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  
  List<Map<String, dynamic>> _results = [];

  Future<void> _search() async {
  final q = _controller.text.trim();
  if (q.isEmpty) return;

  setState(() => _loading = true);

  try {
    final spotify = SpotifyService();

    // ✅ ENSURE AUTH BEFORE SEARCH
    final token = await spotify.getAccessToken();
    if (token == null) {
      await spotify.authenticateWithSpotify(
        FirebaseAuth.instance.currentUser!.uid,
      );
    }

    final res = await spotify.searchTracksParsed(q);
    setState(() => _results = res);
  } catch (e, st) {
    debugPrint('Spotify search error: $e');
    debugPrintStack(stackTrace: st);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }

  setState(() => _loading = false);
}


  Future<void> _addSong(Map<String, dynamic> track) async {
    final ref = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('playlist')
        .doc(track['spotifyId'])
        .set({
      // 🔑 Required by model
      'trackId': track['spotifyId'],
      'addedBy': FirebaseAuth.instance.currentUser!.uid,
      'addedAt': FieldValue.serverTimestamp(),
      'status': 'queued',
      'votes': {},
      'voteScore': 0,

      // 🎵 Spotify metadata (nested correctly)
      'metadata': {
        'title': track['title'],
        'artists': track['artists'],
        'duration_ms': track['durationMs'] ?? 0,
        'preview_url': track['previewUrl'],
        'artwork': track['artwork'],
      },
    });


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Song added')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Add Song'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search Spotify',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_loading)
            const CircularProgressIndicator()
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final t = _results[i];
                  return ListTile(
                    leading: t['artwork'] != null
                        ? Image.network(t['artwork'],
                            width: 50, fit: BoxFit.cover)
                        : const Icon(Icons.music_note),
                    title: Text(t['title']),
                    subtitle: Text(t['artists'].join(', ')),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addSong(t),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
