import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../constants/colors.dart';
import '../../models/playlist_item.dart';
import '../../services/voting_service.dart';
import 'chat_screen.dart';
import 'package:vibz/spotify_search_screen.dart';
class RoomScreen extends StatefulWidget {
  final String roomId;
  const RoomScreen({super.key, required this.roomId});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  String _searchQuery = '';
  bool _autoAdvanceInProgress = false;

  @override
  Widget build(BuildContext context) {
    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    final playlistRef = roomRef.collection('playlist');

    return Scaffold(
      backgroundColor: AppColors.bg,

      /* ================= APP BAR ================= */

      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text(
          'Room',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: AppColors.text),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(roomId: widget.roomId),
                ),
              );
            },
          ),
        ],
      ),

      /* ================= BODY ================= */

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: roomRef.snapshots(),
        builder: (context, roomSnap) {
          if (!roomSnap.hasData || roomSnap.data!.data() == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final room = roomSnap.data!.data()!;
          final String? currentItemId = room['currentItemId'];
          final String playState = room['playState'] ?? 'paused';
          final bool autoplay = room['settings']?['autoplay'] ?? false;

          return Column(
            children: [
              _SearchBar(
                onChanged: (q) => setState(() => _searchQuery = q),
              ),

              _RoomStatusHeader(
                currentItemId: currentItemId,
                playState: playState,
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: playlistRef.snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final items = snap.data!.docs
                        .map((d) => PlaylistItem.fromFirestore(d))
                        .where((item) {
                          if (_searchQuery.isEmpty) return true;
                          final q = _searchQuery.toLowerCase();
                          return item.title.toLowerCase().contains(q) ||
                              item.artists
                                  .join(' ')
                                  .toLowerCase()
                                  .contains(q);
                        })
                        .toList()
                      ..sort((a, b) {
                        if (b.voteScore != a.voteScore) {
                          return b.voteScore.compareTo(a.voteScore);
                        }
                        return a.addedAt.compareTo(b.addedAt);
                      });

                    /* ========= AUTOPLAY LOGIC ========= */

                    if (autoplay &&
                        !_autoAdvanceInProgress &&
                        currentItemId == null &&
                        items.isNotEmpty) {
                      _autoAdvanceInProgress = true;
                      _promoteNextSong(roomRef, items.first.id);
                    }

                    if (items.isEmpty) {
                      return const _EmptyPlaylist();
                    }

                    final currentItem = items
                        .where((e) => e.id == currentItemId)
                        .toList()
                        .firstOrNull;

                    return Column(
                      children: [
                        _NowPlayingBar(item: currentItem),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return _PlaylistTile(
                                roomId: widget.roomId,
                                item: items[index],
                                isPlaying:
                                    items[index].id == currentItemId,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      /* ================= FAB ================= */

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.search),
        label: const Text('Add Song'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SpotifySearchScreen(roomId: widget.roomId),
            ),
          );
        },
      ),

    );
  }

  Future<void> _promoteNextSong(
      DocumentReference roomRef, String itemId) async {
    await roomRef.update({
      'currentItemId': itemId,
      'playState': 'playing',
    });
    _autoAdvanceInProgress = false;
  }
}

/* ================= SEARCH BAR ================= */

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search songs or artists',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/* ================= ROOM STATUS ================= */

class _RoomStatusHeader extends StatelessWidget {
  final String? currentItemId;
  final String playState;

  const _RoomStatusHeader({
    required this.currentItemId,
    required this.playState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            playState == 'playing'
                ? Icons.graphic_eq
                : Icons.pause_circle_outline,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Text(
            currentItemId != null
                ? 'Room is playing'
                : 'Waiting for next song',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= NOW PLAYING ================= */

class _NowPlayingBar extends StatelessWidget {
  final PlaylistItem? item;

  const _NowPlayingBar({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill,
              color: AppColors.primary, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: item == null
                ? const Text(
                    'No song playing',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        item!.artists.join(', '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/* ================= PLAYLIST TILE ================= */

class _PlaylistTile extends StatelessWidget {
  final String roomId;
  final PlaylistItem item;
  final bool isPlaying;

  const _PlaylistTile({
    required this.roomId,
    required this.item,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('votes')
          .doc('${uid}_${item.id}')
          .snapshots(),
      builder: (context, snap) {
        final myVote = snap.data?.data()?['vote'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isPlaying
                ? AppColors.primary.withOpacity(0.18)
                : AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isPlaying ? AppColors.primary : Colors.black12,
            ),
          ),
          child: Row(
            children: [
              if (item.artwork != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item.artwork!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Icon(Icons.music_note, size: 48),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      item.artists.join(', '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    if (isPlaying)
                      const Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),

              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.keyboard_arrow_up,
                      color: myVote == 1
                          ? AppColors.primary
                          : AppColors.muted,
                    ),
                    onPressed: isPlaying
                        ? null
                        : () => VotingService().voteOnTrack(
                              roomId: roomId,
                              itemId: item.id,
                              vote: 1,
                            ),
                  ),
                  Text(item.voteScore.toString()),
                  IconButton(
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: myVote == -1
                          ? AppColors.primary
                          : AppColors.muted,
                    ),
                    onPressed: isPlaying
                        ? null
                        : () => VotingService().voteOnTrack(
                              roomId: roomId,
                              itemId: item.id,
                              vote: -1,
                            ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ================= EMPTY STATE ================= */

class _EmptyPlaylist extends StatelessWidget {
  const _EmptyPlaylist();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('No songs yet',
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Add a song to start the vibe'),
        ],
      ),
    );
  }
}
