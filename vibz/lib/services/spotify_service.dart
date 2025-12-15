// lib/services/spotify_service.dart
import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class SpotifyService {
  // TODO: Replace placeholders below BEFORE running:
  // 1) Replace <YOUR_SPOTIFY_CLIENT_ID> with the Client ID from Spotify dashboard.
  // 2) Replace <YOUR_REDIRECT_URI> with the exact Redirect URI you registered: e.g. 'com.vibz.app://callback'
  static const String _clientId = 'c6fd756a008c4fdda16ab15e7fe98ff8';
  static const String _redirectUri = 'com.example.vibz://callback';

  // Scopes you need for profile & search/preview
  static const List<String> _scopes = [
    'user-read-email',
    'user-read-private',
  ];

  final FlutterAppAuth _appAuth = FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // secure storage keys
  static const String _kAccessToken = 'spotify_access_token';
  static const String _kRefreshToken = 'spotify_refresh_token';
  static const String _kExpiresAt = 'spotify_expires_at';
  static const String _kSpotifyId = 'spotify_id';

  // PKCE authorize + token exchange
  Future<Map<String, dynamic>> authenticateWithSpotify(String firebaseUid) async {
    final result =
    await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _clientId,
        _redirectUri,
        //androidPackageName: 'com.example.vibz',
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: 'https://accounts.spotify.com/authorize',
          tokenEndpoint: 'https://accounts.spotify.com/api/token',
        ),
        scopes: _scopes,
        
      ),
    );
    if (result.accessToken == null) {
      throw Exception('Spotify authentication failed');
    }


    // store tokens
    await _secureStorage.write(key: _kAccessToken, value: result.accessToken);
    if (result.refreshToken != null) {
      await _secureStorage.write(key: _kRefreshToken, value: result.refreshToken);
    }
    final expMillis = result.accessTokenExpirationDateTime?.millisecondsSinceEpoch ??
        (DateTime.now().millisecondsSinceEpoch + 3600 * 1000);
    await _secureStorage.write(key: _kExpiresAt, value: expMillis.toString());

    // fetch spotify profile
    final profile = await _fetchProfile(result.accessToken!);

    // write link into Firestore user doc (requires user signed-in to Firebase)
    if (firebaseUid.isNotEmpty) {
      await _firestore.collection('users').doc(firebaseUid).set({
        'spotifyLinked': true,
        'spotifyId': profile['id'],
        'spotifyProfile': profile,
        'spotifyLinkedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _secureStorage.write(key: _kSpotifyId, value: profile['id']);
    }

    return profile;
  }

  Future<Map<String, dynamic>> _fetchProfile(String accessToken) async {
    final resp = await http.get(
      Uri.parse('https://api.spotify.com/v1/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Spotify profile fetch failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<String?> getAccessToken() async {
    final token = await _secureStorage.read(key: _kAccessToken);
    final expiresAtStr = await _secureStorage.read(key: _kExpiresAt);
    if (token == null || expiresAtStr == null) return null;
    final expiresAt = int.tryParse(expiresAtStr) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now > expiresAt - 5000) {
      return await _refreshToken();
    }
    return token;
  }

  Future<String?> _refreshToken() async {
    final refreshToken = await _secureStorage.read(key: _kRefreshToken);
    if (refreshToken == null) return null;
    final resp = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': _clientId,
      },
    );
    if (resp.statusCode != 200) {
      // clear tokens on failure
      await _secureStorage.deleteAll();
      return null;
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final newAccess = body['access_token'] as String?;
    final expiresIn = body['expires_in'] as int? ?? 3600;
    if (newAccess != null) {
      final expiry = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
      await _secureStorage.write(key: _kAccessToken, value: newAccess);
      await _secureStorage.write(key: _kExpiresAt, value: expiry.toString());
      return newAccess;
    }
    return null;
  }

  // Example helper: search tracks
  Future<Map<String, dynamic>> searchTracks(String query) async {
  final token = await getAccessToken();
  if (token == null) {
    throw Exception('No Spotify access token available. Authenticate first.');
  }

  final encoded = Uri.encodeQueryComponent(query);

  final uri = Uri.parse(
    'https://api.spotify.com/v1/search'
    '?q=$encoded'
    '&type=track'
    '&limit=20'
    '&market=from_token',
  );

  final resp = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (resp.statusCode != 200) {
    throw Exception(
      'Spotify search failed: ${resp.statusCode} ${resp.body}',
    );
  }

  return jsonDecode(resp.body) as Map<String, dynamic>;
}



  Future<void> clearSpotifySession() async {
  await _secureStorage.deleteAll();
}



  Future<List<Map<String, dynamic>>> searchTracksParsed(String query) async {
    final data = await searchTracks(query);

    final items = (data['tracks']?['items'] as List?) ?? [];

    return items.map<Map<String, dynamic>>((t) {
      return {
        'spotifyId': t['id'],
        'title': t['name'],
        'artists': (t['artists'] as List)
            .map((a) => a['name'])
            .toList(),
        'artwork': (t['album']?['images'] as List?)?.isNotEmpty == true
            ? t['album']['images'][0]['url']
            : null,
        'previewUrl': t['preview_url'], // nullable (expected)
        'durationMs': t['duration_ms'],
      };
    }).toList();
  }



}
