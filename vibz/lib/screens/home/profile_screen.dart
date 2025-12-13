// lib/screens/home/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<void> _unlinkSpotify(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'spotifyLinked': false,
      'spotifyId': FieldValue.delete(),
      'spotifyProfile': FieldValue.delete(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spotify unlinked')));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['displayName'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'User';
          final email = FirebaseAuth.instance.currentUser?.email ?? '';
          final photo = data['photoURL'] ?? FirebaseAuth.instance.currentUser?.photoURL;
          final spotifyLinked = data['spotifyLinked'] == true;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(radius: 40, backgroundImage: photo != null ? NetworkImage(photo) : null, child: photo == null ? const Icon(Icons.person, size: 40) : null),
                const SizedBox(height: 12),
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(email, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(spotifyLinked ? 'Spotify linked' : 'Spotify not linked'),
                  trailing: spotifyLinked ? ElevatedButton(onPressed: () => _unlinkSpotify(context), child: const Text('Unlink')) : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
