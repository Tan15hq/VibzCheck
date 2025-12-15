import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../constants/colors.dart';
import '../../widgets/room_card.dart';
import '../room/room_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _roomsRef = FirebaseFirestore.instance.collection('rooms');
  String _search = '';

  /* ---------------- CREATE ROOM ---------------- */

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
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Room name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Public room'),
                  const Spacer(),
                  Switch(
                    value: isPublic,
                    onChanged: (v) => setState(() => isPublic = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Vote window: $voteWindow sec'),
              Slider(
                value: voteWindow.toDouble(),
                min: 10,
                max: 120,
                divisions: 11,
                label: '$voteWindow',
                onChanged: (v) => setState(() => voteWindow = v.toInt()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser!.uid;

                final doc = await _roomsRef.add({
                  'name': nameCtrl.text.isEmpty
                      ? 'Room by ${FirebaseAuth.instance.currentUser?.displayName ?? 'User'}'
                      : nameCtrl.text,
                  'createdBy': uid,
                  'createdAt': FieldValue.serverTimestamp(),
                  'isPublic': isPublic,
                  'settings': {
                    'voteWindowSec': voteWindow,
                    'autoplay': true,
                  },
                });

                if (!mounted) return;
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomScreen(roomId: doc.id),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  /* ---------------- JOIN ROOM ---------------- */

  Future<void> _joinRoomByCode() async {
    final codeCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Join Room'),
          content: TextField(
            controller: codeCtrl,
            decoration: const InputDecoration(
              hintText: 'Enter room code',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                final id = codeCtrl.text.trim();
                if (id.isEmpty) return;

                final doc = await _roomsRef.doc(id).get();
                if (!doc.exists) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Room not found')),
                  );
                  return;
                }

                if (!mounted) return;
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomScreen(roomId: id),
                  ),
                );
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }

  /* ---------------- LOGOUT ---------------- */

  Future<void> _logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bg,
        title: const Text(
          'Vibz',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color.fromARGB(255, 122, 113, 113)),
            onPressed: () async {
              final q = await showSearch<String>(
                context: context,
                delegate: _RoomSearchDelegate(),
              );

              if (!mounted || q == null) return;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _search = q);
              });
            },

          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildHeader(),
          _buildActions(),
          _buildRoomsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _createRoomDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  /* ---------------- HEADER ---------------- */

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() as Map<String, dynamic>?;
          final name = data?['displayName']
              ?? FirebaseAuth.instance.currentUser?.displayName
              ?? 'User';
          final spotifyLinked = data?['spotifyLinked'] == true;

          return _card(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 31, 28, 28),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spotifyLinked
                          ? 'Spotify connected'
                          : 'Spotify not connected',
                      style: TextStyle(
                        fontSize: 13,
                        color: spotifyLinked
                            ? AppColors.primary
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /* ---------------- ACTIONS ---------------- */

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _card(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _createRoomDialog,
                child: const Text('Create Room'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary),
                ),
                onPressed: _joinRoomByCode,
                child: const Text(
                  'Join Room',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ---------------- ROOMS ---------------- */

  Widget _buildRoomsList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _search.isEmpty
            ? _roomsRef
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots()
            : _roomsRef
                .where('name', isGreaterThanOrEqualTo: _search)
                .where('name', isLessThanOrEqualTo: '$_search\uf8ff')
                .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No rooms yet.\nCreate one to start the vibe.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final room = d.data() as Map<String, dynamic>;
              return RoomCard(
                roomId: d.id,
                name: room['name'] ?? 'Untitled',
                createdBy: room['createdBy'] ?? '',
                isPublic: room['isPublic'] ?? true,
                onJoin: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomScreen(roomId: d.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /* ---------------- DRAWER ---------------- */

  Drawer _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  /* ---------------- CARD ---------------- */

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(31, 87, 82, 82)),
      ),
      child: child,
    );
  }
}

class _RoomSearchDelegate extends SearchDelegate<String> {
  @override
  String? get searchFieldLabel => 'Search rooms';

  @override
  TextInputAction get textInputAction => TextInputAction.search;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  /// ❌ NOT USED
  @override
  Widget buildResults(BuildContext context) {
    return const SizedBox.shrink();
  }

  /// 👇 CLOSE SEARCH AS SOON AS USER SUBMITS
  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  void showResults(BuildContext context) {
    close(context, query.trim());
  }
}



