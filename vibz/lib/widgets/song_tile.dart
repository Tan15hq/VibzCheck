// song_tile.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/playlist_item.dart';
import '../services/firestore_service.dart';

class SongTile extends StatefulWidget {
  final PlaylistItem item;
  final String roomId;
  final String currentUserId;
  const SongTile({Key? key, required this.item, required this.roomId, required this.currentUserId}) : super(key: key);

  @override
  State<SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<SongTile> {
  final FirestoreService _fs = FirestoreService();
  String _myVote = 'none'; // optimistic local state
  bool _loadingVote = false;

  Future<void> _setVote(String vote) async {
    setState(() { _loadingVote = true; _myVote = vote; });
    try {
      await _fs.setVote(roomId: widget.roomId, itemId: widget.item.itemId, vote: vote);
    } catch (e) {
      // rollback on error
      setState(() { _myVote = 'none'; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vote failed: $e')));
    } finally {
      setState(() { _loadingVote = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final votes = widget.item.votes;
    final up = (votes['up'] ?? 0) as int;
    final down = (votes['down'] ?? 0) as int;

    return ListTile(
      leading: widget.item.artwork != null ? Image.network(widget.item.artwork!, width: 56, height: 56, fit: BoxFit.cover) : const Icon(Icons.music_note, size: 40),
      title: Text(widget.item.title),
      subtitle: Text(widget.item.artists.join(', ')),
      trailing: SizedBox(
        width: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_upward, color: _myVote == 'up' ? Theme.of(context).colorScheme.secondary : null),
                  onPressed: _loadingVote ? null : () {
                    // toggle
                    final newVote = _myVote == 'up' ? 'none' : 'up';
                    _setVote(newVote);
                  },
                ),
                Text('$up'),
              ],
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_downward, color: _myVote == 'down' ? Theme.of(context).colorScheme.error : null),
                  onPressed: _loadingVote ? null : () {
                    final newVote = _myVote == 'down' ? 'none' : 'down';
                    _setVote(newVote);
                  },
                ),
                Text('$down'),
              ],
            ),
          ],
        ),
      ),
      onTap: () {
        // optional: preview play or show details
      },
    );
  }
}
