// search_screen.dart
import 'package:flutter/material.dart';
import '../../services/spotify_service.dart';
import '../../services/firestore_service.dart';

class SearchScreen extends StatefulWidget {
  final String roomId;
  const SearchScreen({super.key, required this.roomId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SpotifyService _spotify = SpotifyService();
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _q = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _tracks = [];

  Future<void> _search(String q) async {
    setState(() { _loading = true; _tracks = []; });
    try {
      final data = await _spotify.searchTracks(q);
      final items = (data['tracks']?['items'] ?? []) as List<dynamic>;
      setState(() {
        _tracks = items.map((t) {
          final artists = (t['artists'] as List<dynamic>).map((a) => a['name'] as String).toList();
          return {
            'id': t['id'],
            'title': t['name'],
            'artists': artists,
            'duration_ms': t['duration_ms'],
            'preview_url': t['preview_url'],
            'artwork': (t['album']?['images'] != null && (t['album']['images'] as List).isNotEmpty) ? t['album']['images'][0]['url'] : null,
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _addTrack(Map<String, dynamic> track) async {
    await _fs.addPlaylistItem(
      roomId: widget.roomId,
      trackId: track['id'],
      title: track['title'],
      artists: List<String>.from(track['artists']),
      durationMs: track['duration_ms'] ?? 30000,
      previewUrl: track['preview_url'],
      artwork: track['artwork'],
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Track added')));
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Spotify'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(controller: _q, decoration: const InputDecoration(hintText: 'Search songs, artists...')),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : () => _search(_q.text.trim()),
                  child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Search'),
                )
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _tracks.isEmpty
                ? const Center(child: Text('No results'))
                : ListView.separated(
                    itemCount: _tracks.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final t = _tracks[i];
                      return ListTile(
                        leading: t['artwork'] != null ? Image.network(t['artwork'], width: 56, height: 56, fit: BoxFit.cover) : const Icon(Icons.music_note),
                        title: Text(t['title']),
                        subtitle: Text((t['artists'] as List).join(', ')),
                        trailing: ElevatedButton(
                          child: const Text('Add'),
                          onPressed: () => _addTrack(t),
                        ),
                      );
                    },
                  ),
            )
          ],
        ),
      ),
    );
  }
}
