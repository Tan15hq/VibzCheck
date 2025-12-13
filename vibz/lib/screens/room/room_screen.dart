// room_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/playlist_item.dart';
import '../../widgets/song_tile.dart';
import '../../screens/room/now_playing_bar.dart';
import '../add_track/search_screen.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;
  const RoomScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final FirestoreService _fs = FirestoreService();
  late final Stream<List<DocumentSnapshot>> _playlistStream;

  @override
  void initState() {
    super.initState();
    _playlistStream = _fs.playlistStream(widget.roomId);
  }

  void _onAddTrack() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(roomId: widget.roomId)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomId}'),
        actions: [
          IconButton(onPressed: _onAddTrack, icon: const Icon(Icons.add)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: _playlistStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snap.data ?? [];
                if (docs.isEmpty) return const Center(child: Text('No tracks yet — add one!'));
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = PlaylistItem.fromDoc(docs[i]);
                    return SongTile(
                      item: item,
                      roomId: widget.roomId,
                      currentUserId: uid,
                    );
                  },
                );
              },
            ),
          ),
          const NowPlayingBar(), // minimal player UI
        ],
      ),
    );
  }
}
