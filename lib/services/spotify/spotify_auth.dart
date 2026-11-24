import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import 'spotify_config.dart';

/// Login Spotify gagal / dibatalin / sesi habis.
class SpotifyAuthException implements Exception {
  const SpotifyAuthException(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;
  @override
  String toString() => message;
}

/// PKCE: kode acak (verifier) & sidik SHA-256-nya (challenge), base64url tanpa '='.
String pkceVerifier([Random? rnd]) {
  final r = rnd ?? Random.secure();
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  return List.generate(64, (_) => chars[r.nextInt(chars.length)]).join();
}

String pkceChallenge(String verifier) =>
    base64Url.encode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');

/// Token Spotify yang disimpan terenkripsi di HP (Android Keystore).
class SpotifyToken {
  const SpotifyToken({required this.access, required this.refresh, required this.expiresAt});
  final String access;
  final String refresh;
  final DateTime expiresAt;

  /// Dianggap habis 60 detik lebih awal, biar gak keburu kedaluwarsa di tengah jalan.
  bool get expired => DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 60)));

  static SpotifyToken fromResponse(Map<String, dynamic> m, {String? previousRefresh}) {
    final access = m['access_token'];
    if (access is! String || access.isEmpty) throw const SpotifyAuthException('Spotify gak ngasih token.');
    final secs = m['expires_in'] is int ? m['expires_in'] as int : 3600;
    return SpotifyToken(
      access: access,
      // Pas refresh, Spotify kadang gak ngirim refresh token baru: pakai yang lama.
      refresh: (m['refresh_token'] as String?) ?? previousRefresh ?? '',
      expiresAt: DateTime.now().add(Duration(seconds: secs)),
    );
  }

  String encode() => jsonEncode({'a': access, 'r': refresh, 'e': expiresAt.millisecondsSinceEpoch});

  static SpotifyToken? decode(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return SpotifyToken(
        access: m['a'] as String,
        refresh: m['r'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(m['e'] as int),
      );
    } catch (_) {
      return null;
    }
  }
}

class SpotifyAuth {
  SpotifyAuth({http.Client? client, FlutterSecureStorage? storage})
      : _http = client ?? http.Client(),
        _store = storage ?? const FlutterSecureStorage();

  static const _key = 'spotify_token';
  static const _tokenUrl = 'https://accounts.spotify.com/api/token';

  final http.Client _http;
  final FlutterSecureStorage _store;
  SpotifyToken? _token;

  Future<bool> get loggedIn async => (await _load()) != null;

  Future<SpotifyToken?> _load() async {
    if (_token != null) return _token;
    try {
      _token = SpotifyToken.decode(await _store.read(key: _key));
    } catch (_) {
      _token = null; // data keystore rusak (mis. habis restore HP) → login ulang
    }
    return _token;
  }

  Future<void> _save(SpotifyToken t) async {
    _token = t;
    await _store.write(key: _key, value: t.encode());
  }

  Future<void> logout() async {
    _token = null;
    await _store.delete(key: _key);
  }

  /// Buka halaman login Spotify (Authorization Code + PKCE), tukar kode jadi token.
  Future<void> login() async {
    if (!spotifyConfigured) throw const SpotifyAuthException('Client ID Spotify belum diisi.');
    final verifier = pkceVerifier();
    final state = pkceVerifier().substring(0, 24);
    final url = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': spotifyClientId,
      'response_type': 'code',
      'redirect_uri': spotifyRedirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': pkceChallenge(verifier),
      'scope': spotifyScopes.join(' '),
      'state': state,
    });

    final String result;
    try {
      result = await FlutterWebAuth2.authenticate(url: url.toString(), callbackUrlScheme: spotifyCallbackScheme);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('CANCELED') || msg.contains('CANCELLED')) {
        throw const SpotifyAuthException('Login dibatalin.', cancelled: true);
      }
      throw SpotifyAuthException('Halaman login gak bisa dibuka ($msg).');
    }

    final q = Uri.parse(result).queryParameters;
    if (q['error'] != null) {
      throw SpotifyAuthException(q['error'] == 'access_denied'
          ? 'Izin ke Spotify ditolak.'
          : 'Spotify nolak login: ${q['error']}.');
    }
    if (q['state'] != state) throw const SpotifyAuthException('Login gak valid (state beda). Coba lagi.');
    final code = q['code'];
    if (code == null) throw const SpotifyAuthException('Spotify gak ngasih kode login.');

    final res = await _http.post(Uri.parse(_tokenUrl), body: {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': spotifyRedirectUri,
      'client_id': spotifyClientId,
      'code_verifier': verifier,
    });
    if (res.statusCode != 200) {
      throw SpotifyAuthException('Tukar token gagal (${res.statusCode}). Cek Redirect URI di dashboard Spotify.');
    }
    await _save(SpotifyToken.fromResponse(jsonDecode(res.body) as Map<String, dynamic>));
  }

  /// Token yang masih berlaku; otomatis diperbarui kalau udah habis.
  Future<String> accessToken({bool forceRefresh = false}) async {
    final t = await _load();
    if (t == null) throw const SpotifyAuthException('Belum login Spotify.');
    if (!forceRefresh && !t.expired) return t.access;
    if (t.refresh.isEmpty) {
      await logout();
      throw const SpotifyAuthException('Sesi Spotify habis, login lagi ya.');
    }
    final res = await _http.post(Uri.parse(_tokenUrl), body: {
      'grant_type': 'refresh_token',
      'refresh_token': t.refresh,
      'client_id': spotifyClientId,
    });
    if (res.statusCode != 200) {
      await logout();
      throw const SpotifyAuthException('Sesi Spotify habis, login lagi ya.');
    }
    final next = SpotifyToken.fromResponse(jsonDecode(res.body) as Map<String, dynamic>, previousRefresh: t.refresh);
    await _save(next);
    return next.access;
  }
}
