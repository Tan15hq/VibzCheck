import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../constants/colors.dart';
import 'spotify_connect_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  void _showSnackbar(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authSvc = ref.watch(authServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              Text('Vibz', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text('Collaborative music rooms', style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Continue with Google'),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  try {
                    await authSvc.signInWithGoogle();
                    _showSnackbar(context, 'Signed in with Google');
                  } catch (e) {
                    _showSnackbar(context, 'Google sign-in failed: $e');
                  }
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  _showSnackbar(context, 'Email auth not implemented — use Google for now');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Sign in with email'),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpotifyConnectScreen()));
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Link Spotify (optional)'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
