import 'package:flutter/material.dart';
import '../models/playlist_item.dart';
import '../services/firestore_service.dart';
import '../constants/colors.dart';
import '../services/preview_cache_service.dart';
import '../services/preview_player_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SongTile extends StatefulWidget {
  final PlaylistItem item;
  final String roomId;
  final String currentUserId;

  const SongTile({
    super.key,
    required this.item,
    required this.roomId,
    required this.currentUserId,
  });

  @override
  State<SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<SongTile> {
  final FirestoreService _fs = FirestoreService();
  final _cache = PreviewCacheService();
  final _player = PreviewPlayerService();
  bool _playingPreview = false;

  String _myVote = 'none'; // optimistic local state
  bool _loadingVote = false;

  Future<void> _setVote(String vote) async {
    setState(() {
      _loadingVote = true;
      _myVote = vote;
    });

    try {
      await _fs.setVote(
        roomId: widget.roomId,
        itemId: widget.item.trackId, // ✅ FIXED
        vote: vote,
      );
    } catch (e) {
      // rollback on error
      setState(() => _myVote = 'none');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote failed')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingVote = false);
      }
    }
  }
  Future<void> _togglePreview() async {
    if (_playingPreview) {
      await _player.stop();
      setState(() => _playingPreview = false);
      return;
    }

    final file = await _cache.getOrDownload(
      trackId: widget.item.trackId,
      previewUrl: widget.item.previewUrl,
    );

    if (file == null) return;

    await _player.playFile(
      file,
      onComplete: () async {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .update({'playState': 'idle'});
      },
    );

    setState(() => _playingPreview = true);
  }

  @override
  Widget build(BuildContext context) {
    final votes = widget.item.votes;
    final up = (votes['up'] ?? 0) as int;
    final down = (votes['down'] ?? 0) as int;

    final moodLabel = widget.item.mood?['label'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: widget.item.artwork != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.item.artwork!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.music_note, size: 40),

        title: Text(
          widget.item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.artists.join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            if (moodLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: Text(
                    moodLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),

        trailing: SizedBox(
          width: 160,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [

              // ▶️ PLAY / PAUSE PREVIEW
              IconButton(
                icon: Icon(
                  _playingPreview
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 28,
                  color: AppColors.primary,
                ),
                onPressed: widget.item.previewUrl == null
                    ? null
                    : _togglePreview,
              ),

              const SizedBox(width: 8),

              // 👍 UPVOTE
              _VoteButton(
                icon: Icons.arrow_upward,
                active: _myVote == 'up',
                count: up,
                color: AppColors.primary,
                onTap: _loadingVote
                    ? null
                    : () => _setVote(_myVote == 'up' ? 'none' : 'up'),
              ),

              const SizedBox(width: 6),

              // 👎 DOWNVOTE
              _VoteButton(
                icon: Icons.arrow_downward,
                active: _myVote == 'down',
                count: down,
                color: Colors.redAccent,
                onTap: _loadingVote
                    ? null
                    : () => _setVote(_myVote == 'down' ? 'none' : 'down'),
              ),
            ],
          ),
        ),

      ),
    );
  }
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

}

/// SMALL HELPER WIDGET (clean UI)
class _VoteButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final int count;
  final Color color;
  final Function()? onTap; // ✅ no VoidCallback

  const _VoteButton({
    required this.icon,
    required this.active,
    required this.count,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: active ? color : Colors.grey),
          onPressed: onTap,
        ),
        Text(
          '$count',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

