export 'spotify_api.dart';
export 'spotify_auth.dart';
export 'spotify_config.dart';
export 'track_matcher.dart';

import 'spotify_api.dart';
import 'spotify_auth.dart';

/// Satu sesi Spotify buat seluruh app (token dibaca dari penyimpanan aman).
final spotifyAuth = SpotifyAuth();
final spotifyApi = SpotifyApi(spotifyAuth);

/// Nama playlist Nova yang belum dipakai: "Nyetir", "Nyetir (2)", ...
String uniquePlaylistName(String name, Iterable<String> taken) {
  final used = {for (final t in taken) t.toLowerCase()};
  final base = name.trim().isEmpty ? 'Dari Spotify' : name.trim();
  if (!used.contains(base.toLowerCase())) return base;
  for (var i = 2;; i++) {
    final c = '$base ($i)';
    if (!used.contains(c.toLowerCase())) return c;
  }
}
