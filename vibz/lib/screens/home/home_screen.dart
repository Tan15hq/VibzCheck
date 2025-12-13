// lib/screens/home/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/firestore_service.dart';
import '../room/room_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../../widgets/room_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _roomsRef = FirebaseFirestore.instance.collection('rooms');
  final FirestoreService _fs = FirestoreService();
  String _search = '';

  Future<void> _createRoomDialog() async {
    final nameCtrl = TextEditingController();
    bool isPublic = true;
    int voteWindow = 30;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Room name')),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Public'),
                  Switch(value: isPublic, onChanged: (v) { isPublic = v; setState((){}); }),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Vote window (sec)'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: voteWindow.toDouble(),
                      min: 10,
                      max: 120,
                      divisions: 11,
                      label: '$voteWindow',
                      onChanged: (v) { voteWindow = v.toInt(); setState((){}); },
                    ),
                  ),
                  Text('$voteWindow s'),
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                final doc = await _roomsRef.add({
                  'name': nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Room by ${FirebaseAuth.instance.currentUser?.displayName ?? 'User'}',
                  'createdBy': uid,
                  'createdAt': FieldValue.serverTimestamp(),
                  'isPublic': isPublic,
                  'settings': {'voteWindowSec': voteWindow, 'autoplay': true},
                });
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoomScreen(roomId: doc.id)));
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinRoomByCode() async {
    final codeCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Join Room by Code'),
          content: TextField(controller: codeCtrl, decoration: const InputDecoration(hintText: 'Enter room ID / code')),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final id = codeCtrl.text.trim();
                if (id.isEmpty) return;
                final doc = await _roomsRef.doc(id).get();
                if (!doc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room not found')));
                  return;
                }
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoomScreen(roomId: id)));
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      // sign out Google (if used) and Firebase
      await GoogleSignIn(scopes: ['email']).signOut().catchError((_) {});
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibz — Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final q = await showSearch<String>(
                context: context,
                delegate: _RoomSearchDelegate(),
              );
              if (q != null) setState(() => _search = q);
            },
          )
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
                builder: (ctx, snap) {
                  final data = snap.data?.data() as Map<String, dynamic>?;
                  final name = data?['displayName'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'User';
                  final photo = data?['photoURL'] ?? FirebaseAuth.instance.currentUser?.photoURL;
                  final spotifyLinked = data?['spotifyLinked'] == true;
                  return UserAccountsDrawerHeader(
                    accountName: Text(name),
                    accountEmail: Text(spotifyLinked ? 'Spotify connected' : 'No Spotify'),
                    currentAccountPicture: CircleAvatar(backgroundImage: photo != null ? NetworkImage(photo) : null, child: photo == null ? const Icon(Icons.person) : null),
                  );
                },
              ),
              ListTile(leading: const Icon(Icons.person), title: const Text('Profile'), onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
              }),
              ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await _logout();
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Summary header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text('Available Rooms', style: Theme.of(context).textTheme.titleMedium)),
                TextButton.icon(onPressed: _joinRoomByCode, icon: const Icon(Icons.login), label: const Text('Join by code')),
              ],
            ),
          ),

          // Rooms list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _search.trim().isEmpty
                ? _roomsRef.orderBy('createdAt', descending: true).limit(50).snapshots()
                : _roomsRef.where('name', isGreaterThanOrEqualTo: _search).where('name', isLessThanOrEqualTo: '$_search\uf8ff').snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('No rooms yet. Create one!'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final room = d.data() as Map<String, dynamic>;
                    return RoomCard(
                      roomId: d.id,
                      name: room['name'] ?? 'Untitled',
                      createdBy: room['createdBy'] ?? '',
                      isPublic: room['isPublic'] ?? true,
                      onJoin: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoomScreen(roomId: d.id))),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createRoomDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Simple search delegate returning the query
class _RoomSearchDelegate extends SearchDelegate<String> {
  @override
  String? get searchFieldLabel => 'Search rooms';

  @override
  List<Widget>? buildActions(BuildContext context) => [ IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '') ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) => const SizedBox.shrink();
}
