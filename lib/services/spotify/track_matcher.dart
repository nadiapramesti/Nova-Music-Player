import '../../models.dart';

/// Lagu dari playlist Spotify (cuma info, gak ada file).
class SpotifyTrack {
  const SpotifyTrack({required this.title, required this.artists, this.album = '', this.durationMs = 0});
  final String title;
  final List<String> artists;
  final String album;
  final int durationMs;

  String get artistLine => artists.join(', ');
}

/// Hasil cocokin playlist Spotify ke pustaka Nova.
class MatchResult {
  const MatchResult({required this.matched, required this.missing});

  /// Pasangan (lagu Spotify, lagu lokal) sesuai urutan playlist.
  final List<(SpotifyTrack, Song)> matched;

  /// Lagu yang belum ada di HP.
  final List<SpotifyTrack> missing;

  List<int> get songIds => [for (final (_, s) in matched) s.id];
}

const _fold = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', 'ß': 'ss', 'œ': 'oe', 'æ': 'ae',
};

String _basic(String s) {
  var t = s.toLowerCase().replaceAll('’', "'").replaceAll('&', ' and ');
  final b = StringBuffer();
  for (final ch in t.split('')) {
    b.write(_fold[ch] ?? ch);
  }
  return b.toString();
}

String _clean(String s) =>
    s.replaceAll(RegExp(r"'"), '').replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ').trim().replaceAll(RegExp(r'\s+'), ' ');

// Isi kurung yang cuma "bumbu": feat, remaster, versi, edit, mono/stereo, dll.
final _noiseWords = RegExp(
  r'\b(feat|ft|featuring|with|remaster|remastered|version|edit|radio|mono|stereo|deluxe|bonus|explicit|clean|single|original|from)\b',
);

/// Judul ala pembanding: huruf kecil, tanpa (feat. ...), [Remastered], "- Remaster 2011", tanda baca.
String normalizeTitle(String title) {
  var t = _basic(title);
  // (…) / […] yang isinya bumbu dibuang; yang lain (mis. "(Acoustic)", "(Remix)") disimpan.
  t = t.replaceAllMapped(RegExp(r'[\(\[]([^\)\]]*)[\)\]]'), (m) => _noiseWords.hasMatch(m[1]!) ? ' ' : ' ${m[1]} ');
  // " - Remastered 2011", " - Radio Edit", " - Single Version"
  t = t.replaceAllMapped(RegExp(r'\s[-–—]\s(.*)$'), (m) => _noiseWords.hasMatch(m[1]!) ? '' : ' ${m[1]}');
  // "Judul feat. Artis" tanpa kurung
  t = t.replaceFirst(RegExp(r'\s(feat|ft|featuring)\.?\s.*$'), '');
  return _clean(t);
}

/// Pecah teks artis lokal ("Ariana Grande/Future", "A feat. B", "A & B") jadi daftar.
List<String> splitArtists(String artist) {
  final t = _basic(artist);
  return t
      .split(RegExp(r'\s*(?:/|;|,|\s\+\s|\sand\s|\sx\s|\sfeat\.?\s|\sft\.?\s|\sfeaturing\s|\svs\.?\s)\s*'))
      .map(_clean)
      .where((e) => e.isNotEmpty)
      .toList();
}

String normalizeArtist(String artist) => _clean(_basic(artist));

/// Cocokin lagu Spotify ke pustaka lokal yang udah ada (gak scan ulang).
/// 1) judul sama + artis pertama sama persis (dengan salah satu artis lokal)
/// 2) judul sama + artis nyangkut sebagian (salah satu nama mengandung yang lain)
/// Kalau calonnya lebih dari satu, ambil yang durasinya paling dekat.
MatchResult matchTracks(List<SpotifyTrack> tracks, List<Song> library) {
  final byTitle = <String, List<Song>>{};
  for (final s in library) {
    byTitle.putIfAbsent(normalizeTitle(s.title), () => []).add(s);
  }
  final localArtists = <int, List<String>>{};
  List<String> artistsOf(Song s) => localArtists.putIfAbsent(s.id, () => splitArtists(s.artist));

  Song? closest(List<Song> c, int ms) {
    if (c.isEmpty) return null;
    if (ms <= 0 || c.length == 1) return c.first;
    c.sort((a, b) => (a.durationMs - ms).abs().compareTo((b.durationMs - ms).abs()));
    return c.first;
  }

  final matched = <(SpotifyTrack, Song)>[];
  final missing = <SpotifyTrack>[];
  for (final t in tracks) {
    final candidates = byTitle[normalizeTitle(t.title)] ?? const <Song>[];
    final spArtists = [for (final a in t.artists) normalizeArtist(a)]..removeWhere((e) => e.isEmpty);
    Song? hit;
    if (candidates.isNotEmpty && spArtists.isNotEmpty) {
      final first = spArtists.first;
      hit = closest([for (final s in candidates) if (artistsOf(s).contains(first)) s], t.durationMs);
      hit ??= closest([
        for (final s in candidates)
          if (artistsOf(s).any((l) => spArtists.any((a) => l.contains(a) || a.contains(l))) ||
              spArtists.any((a) => normalizeArtist(s.artist).contains(a)))
            s,
      ], t.durationMs);
    }
    if (hit != null) {
      matched.add((t, hit));
    } else {
      missing.add(t);
    }
  }
  return MatchResult(matched: matched, missing: missing);
}
