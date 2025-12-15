import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'providers/user_doc_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/spotify_onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'constants/colors.dart';
import 'providers/spotify_oauth_provider.dart';

class VibzApp extends ConsumerWidget {
  const VibzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final oauthBusy = ref.watch(spotifyOauthInProgressProvider);
    return MaterialApp(
      title: 'Vibz',
      theme: ThemeData.dark().copyWith(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bg,
      ),
      home: authState.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) =>
            const Scaffold(body: Center(child: Text('Auth error'))),
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }

          final userDoc = ref.watch(userDocProvider(user.uid));

          return userDoc.when(
            loading: () =>
                const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (_, __) => const HomeScreen(),
            data: (doc) {
              final onboardingDone =
                  doc.data()?['spotifyOnboardingDone'] == true;

              return onboardingDone
                  ? const HomeScreen()
                  : const SpotifyOnboardingScreen();
            },
          );
        },
      ),


    );
  }
}
