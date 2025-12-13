import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/spotify_service.dart';

class SpotifyConnectScreen extends StatefulWidget {
  const SpotifyConnectScreen({Key? key}) : super(key: key);

  @override
  State<SpotifyConnectScreen> createState() => _SpotifyConnectScreenState();
}

class _SpotifyConnectScreenState extends State<SpotifyConnectScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  bool _loading = false;
  String? _status;

  Future<void> _connect() async {
    setState(() { _loading = true; _status = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('You must sign in first (Google/email).');
      final profile = await _spotifyService.authenticateWithSpotify(user.uid);
      setState(() { _status = 'Connected as ${profile['display_name'] ?? profile['id']}'; });
    } catch (e) {
      setState(() { _status = 'Spotify connect failed: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Spotify')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Link your Spotify account to search and preview songs.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _connect,
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Connect with Spotify'),
            ),
            const SizedBox(height: 12),
            if (_status != null) Text(_status!),
            const SizedBox(height: 24),
            const Text('If the browser does not return to the app, verify the redirect URI in Spotify dashboard and your Android/iOS config.'),
          ],
        ),
      ),
    );
  }
}
