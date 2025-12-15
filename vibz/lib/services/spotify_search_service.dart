import 'dart:convert';
import 'package:http/http.dart' as http;
import 'spotify_service.dart';

class SpotifySearchService {
  final SpotifyService _spotify;

  SpotifySearchService(this._spotify);

  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    final token = await _spotify.getAccessToken();
    if (token == null) {
      throw Exception('Spotify not authenticated');
    }

    final uri = Uri.parse(
      'https://api.spotify.com/v1/search'
      '?q=${Uri.encodeQueryComponent(query)}'
      '&type=track'
      '&limit=20',
    );

    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Spotify search failed');
    }

    final data = jsonDecode(resp.body);
    final items = data['tracks']['items'] as List<dynamic>;

    return items.map((t) {
      return {
        'trackId': t['id'],
        'title': t['name'],
        'artists':
            (t['artists'] as List).map((a) => a['name']).toList(),
        'durationMs': t['duration_ms'],
        'previewUrl': t['preview_url'],
        'artwork': t['album']['images'].isNotEmpty
            ? t['album']['images'][0]['url']
            : null,
      };
    }).toList();
  }
}
