import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/spotify_service.dart';

final spotifyServiceProvider = Provider<SpotifyService>((ref) {
  return SpotifyService();
});
