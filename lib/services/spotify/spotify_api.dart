import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'spotify_auth.dart';
import 'track_matcher.dart';

/// Error dari Web API yang perlu dijelasin ke pengguna.
class SpotifyApiException implements Exception {
  const SpotifyApiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class SpotifyPlaylist {
  const SpotifyPlaylist({
    required this.id,
    required this.name,
    required this.total,
    this.imageUrl,
    this.ownerName = '',
    this.mine = true,
  });

  final String id;
  final String name;
  final int total;
  final String? imageUrl;
  final String ownerName;

  /// Punya sendiri / kolaboratif. Playlist orang lain isinya gak bisa dibaca di Development Mode.
  final bool mine;

  static SpotifyPlaylist? fromJson(Map<String, dynamic> m, String? myId) {
    final id = m['id'];
    if (id is! String) return null;
    // Feb 2026: "tracks" diganti "items"; dua-duanya dibaca biar aman.
    final box = (m['items'] ?? m['tracks']);
    final total = box is Map && box['total'] is int ? box['total'] as int : 0;
    final images = m['images'];
    String? img;
    if (images is List && images.isNotEmpty && images.first is Map) {
      // Gambar paling kecil yang masih >= 120px biar hemat kuota.
      final list = images.whereType<Map>().toList()
        ..sort((a, b) => ((a['width'] as int?) ?? 0).compareTo((b['width'] as int?) ?? 0));
      img = (list.firstWhere((e) => ((e['width'] as int?) ?? 640) >= 120, orElse: () => list.last)['url']) as String?;
    }
    final owner = m['owner'] is Map ? m['owner'] as Map : const {};
    return SpotifyPlaylist(
      id: id,
      name: (m['name'] as String?)?.trim().isNotEmpty == true ? (m['name'] as String).trim() : 'Tanpa nama',
      total: total,
      imageUrl: img,
      ownerName: (owner['display_name'] as String?) ?? '',
      mine: m['collaborative'] == true || myId == null || owner['id'] == myId,
    );
  }
}

/// Ambil lagu dari satu entri playlist. Null kalau bukan lagu (podcast, episode, kosong).
SpotifyTrack? trackFromItem(Object? entry) {
  if (entry is! Map) return null;
  final t = entry['item'] ?? entry['track'];
  if (t is! Map || t['type'] != 'track') return null;
  final name = t['name'];
  if (name is! String || name.trim().isEmpty) return null;
  final artists = [
    if (t['artists'] is List)
      for (final a in t['artists'] as List)
        if (a is Map && a['name'] is String && (a['name'] as String).isNotEmpty) a['name'] as String,
  ];
  return SpotifyTrack(
    title: name.trim(),
    artists: artists,
    album: t['album'] is Map ? ((t['album'] as Map)['name'] as String? ?? '') : '',
    durationMs: t['duration_ms'] is int ? t['duration_ms'] as int : 0,
  );
}

class SpotifyApi {
  SpotifyApi(this.auth, {http.Client? client}) : _http = client ?? http.Client();

  final SpotifyAuth auth;
  final http.Client _http;
  String? _myId;

  Future<Map<String, dynamic>> _get(Uri url) async {
    var refreshed = false;
    for (var attempt = 0; attempt < 4; attempt++) {
      final token = await auth.accessToken(forceRefresh: refreshed && attempt > 0);
      final http.Response res;
      try {
        res = await _http.get(url, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 20));
      } on TimeoutException {
        throw const SpotifyApiException('Spotify kelamaan jawab. Cek internet terus coba lagi.');
      } catch (_) {
        throw const SpotifyApiException('Gak bisa nyambung ke Spotify. Cek internet terus coba lagi.');
      }
      switch (res.statusCode) {
        case 200:
          return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        case 401 when !refreshed:
          refreshed = true; // token ditolak → perbarui sekali lalu ulang
          continue;
        case 401:
          await auth.logout();
          throw const SpotifyApiException('Sesi Spotify habis, login lagi ya.', status: 401);
        case 403:
          throw const SpotifyApiException(
            'Spotify gak ngizinin baca playlist ini. Di Development Mode, cuma playlist '
            'bikinan lu sendiri (atau kolaboratif) yang isinya bisa dibaca. '
            'Pastiin juga akun lu udah ditambahin di User Management dashboard.',
            status: 403,
          );
        case 404:
          throw const SpotifyApiException('Playlist-nya gak ketemu di Spotify.', status: 404);
        case 429:
          final wait = int.tryParse(res.headers['retry-after'] ?? '') ?? 2;
          if (wait > 30) throw const SpotifyApiException('Spotify lagi ngebatesin permintaan. Coba lagi nanti.', status: 429);
          await Future<void>.delayed(Duration(seconds: wait));
          continue;
        default:
          throw SpotifyApiException('Spotify error (${res.statusCode}). Coba lagi bentar.', status: res.statusCode);
      }
    }
    throw const SpotifyApiException('Spotify gak bisa dihubungi. Coba lagi bentar.');
  }

  Future<String?> _me() async {
    if (_myId != null) return _myId;
    try {
      _myId = (await _get(Uri.parse('https://api.spotify.com/v1/me')))['id'] as String?;
    } on SpotifyApiException catch (e) {
      if (e.status == 401) rethrow;
    }
    return _myId;
  }

  /// Semua playlist di akun (ngikutin "next" sampai habis).
  Future<List<SpotifyPlaylist>> myPlaylists() async {
    final me = await _me();
    final out = <SpotifyPlaylist>[];
    Uri? next = Uri.parse('https://api.spotify.com/v1/me/playlists?limit=50');
    while (next != null) {
      final page = await _get(next);
      for (final m in (page['items'] as List? ?? const [])) {
        if (m is Map<String, dynamic>) {
          final p = SpotifyPlaylist.fromJson(m, me);
          if (p != null) out.add(p);
        }
      }
      final n = page['next'];
      next = n is String && n.isNotEmpty ? Uri.parse(n) : null;
    }
    return out;
  }

  /// Lagu-lagu di playlist (GET /playlists/{id}/items, Feb 2026). Podcast dll dilewatin.
  Future<List<SpotifyTrack>> playlistTracks(String id, {void Function(int read)? onProgress}) async {
    final out = <SpotifyTrack>[];
    Uri? next = Uri.parse('https://api.spotify.com/v1/playlists/$id/items?limit=100');
    while (next != null) {
      final page = await _get(next);
      for (final e in (page['items'] as List? ?? const [])) {
        final t = trackFromItem(e);
        if (t != null) out.add(t);
      }
      onProgress?.call(out.length);
      final n = page['next'];
      next = n is String && n.isNotEmpty ? Uri.parse(n) : null;
    }
    return out;
  }
}
