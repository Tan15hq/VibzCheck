import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/colors.dart';
import '../../providers/spotify_provider.dart';
import '../../providers/spotify_oauth_provider.dart';

class SpotifyOnboardingScreen extends ConsumerWidget {
  const SpotifyOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotify = ref.read(spotifyServiceProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              const Icon(
                Icons.music_note,
                size: 72,
                color: AppColors.primary,
              ),

              const SizedBox(height: 24),

              Text(
                'Connect Spotify',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Link your Spotify account to add tracks, vote, and match the vibe in real time.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              /// CONNECT SPOTIFY
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  if (user == null) return;

                  final oauthFlag =
                      ref.read(spotifyOauthInProgressProvider.notifier);
                  oauthFlag.state = true;

                  try {
                    await spotify.authenticateWithSpotify(user.uid);

                    // MARK ONBOARDING COMPLETE (DO NOT NAVIGATE)
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .set(
                          {'spotifyOnboardingDone': true},
                          SetOptions(merge: true),
                        );
                  } catch (e) {
                    debugPrint('SPOTIFY AUTH ERROR: $e');

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Spotify connection failed'),
                      ),
                    );
                  } finally {
                    oauthFlag.state = false;
                  }
                },
                child: const Text('Connect Spotify'),
              ),

              const SizedBox(height: 12),

              /// SKIP FOR NOW
              TextButton(
                onPressed: () async {
                  if (user == null) return;

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set(
                        {'spotifyOnboardingDone': true},
                        SetOptions(merge: true),
                      );
                },
                child: const Text('Skip for now'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
