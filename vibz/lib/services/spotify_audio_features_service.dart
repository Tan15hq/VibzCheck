import 'dart:convert';
import 'package:http/http.dart' as http;
import 'spotify_service.dart';

class SpotifyAudioFeaturesService {
  final SpotifyService _spotify;

  SpotifyAudioFeaturesService(this._spotify);

  Future<Map<String, dynamic>> fetchMood(String trackId) async {
    final token = await _spotify.getAccessToken();
    if (token == null) {
      throw Exception('Spotify not authenticated');
    }

    final resp = await http.get(
      Uri.parse('https://api.spotify.com/v1/audio-features/$trackId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Audio features fetch failed');
    }

    final data = jsonDecode(resp.body);

    final energy = (data['energy'] ?? 0.0).toDouble();
    final valence = (data['valence'] ?? 0.0).toDouble();
    final dance = (data['danceability'] ?? 0.0).toDouble();
    final tempo = (data['tempo'] ?? 0.0).toDouble();

    return {
      'energy': energy,
      'valence': valence,
      'danceability': dance,
      'tempo': tempo,
      'label': _labelMood(energy, valence, dance),
    };
  }

  String _labelMood(double energy, double valence, double dance) {
    if (energy > 0.7 && dance > 0.7) return 'Party';
    if (valence > 0.6 && energy < 0.6) return 'Chill';
    if (energy < 0.4 && valence < 0.4) return 'Sad';
    if (energy > 0.6 && valence < 0.5) return 'Angsty';
    return 'Balanced';
  }
}
