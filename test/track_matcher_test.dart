import 'package:flutter_test/flutter_test.dart';
import 'package:nova/models.dart';
import 'package:nova/services/spotify/track_matcher.dart';

Song _s(int id, String title, String artist, {int ms = 200000}) => Song(
      id: id,
      title: title,
      artist: artist,
      album: 'X',
      albumId: 1,
      durationMs: ms,
      dateAdded: id,
      path: '/m/$id.mp3',
      uri: 'content://x/$id',
    );

SpotifyTrack _t(String title, List<String> artists, {int ms = 0}) =>
    SpotifyTrack(title: title, artists: artists, durationMs: ms);

void main() {
  group('normalizeTitle', () {
    test('buang feat, remaster, versi, tanda baca', () {
      expect(normalizeTitle('Animals (feat. Someone)'), 'animals');
      expect(normalizeTitle('Yellow - Remastered 2011'), 'yellow');
      expect(normalizeTitle('Burn [Remastered]'), 'burn');
      expect(normalizeTitle('Everyday - Radio Edit'), 'everyday');
      expect(normalizeTitle('Sugar - Single Version'), 'sugar');
      expect(normalizeTitle("Don't Stop Me Now"), 'dont stop me now');
      expect(normalizeTitle('Attention feat. Charlie'), 'attention');
    });

    test('yang bukan bumbu tetap disimpan', () {
      expect(normalizeTitle('Halo (Acoustic)'), 'halo acoustic');
      expect(normalizeTitle('Halo (Remix)'), 'halo remix');
      expect(normalizeTitle('Halo - Live at Wembley'), 'halo live at wembley');
    });

    test('huruf beraksen & huruf Jepang aman', () {
      expect(normalizeTitle('REFLEXIÓN'), 'reflexion');
      expect(normalizeTitle('へたくそ'), 'へたくそ');
    });
  });

  test('splitArtists', () {
    expect(splitArtists('Ariana Grande/Future'), ['ariana grande', 'future']);
    expect(splitArtists('Calvin Harris feat. Rihanna'), ['calvin harris', 'rihanna']);
    expect(splitArtists('Simon & Garfunkel'), ['simon', 'garfunkel']);
  });

  group('matchTracks', () {
    final lib = [
      _s(1, 'Animals', 'Maroon 5'),
      _s(2, 'Everyday', 'Ariana Grande/Future'),
      _s(3, 'Yellow', 'Coldplay'),
      _s(4, 'Burn', 'Ellie Goulding'),
      _s(5, 'Burn', 'Usher'),
      _s(6, 'Halo', 'Beyonce', ms: 260000),
      _s(7, 'Halo', 'Beyonce', ms: 210000),
    ];

    test('judul + artis pertama', () {
      final r = matchTracks([_t('Animals', ['Maroon 5'])], lib);
      expect(r.songIds, [1]);
      expect(r.missing, isEmpty);
    });

    test('artis lokal gabungan tetap ketemu', () {
      expect(matchTracks([_t('Everyday', ['Ariana Grande', 'Future'])], lib).songIds, [2]);
    });

    test('judul sama tapi artis beda → pilih artis yang bener', () {
      expect(matchTracks([_t('Burn', ['Usher'])], lib).songIds, [5]);
    });

    test('fallback artis nyangkut sebagian', () {
      final r = matchTracks([_t('Yellow - Remastered', ['Coldplay Official'])], lib);
      expect(r.songIds, [3]);
    });

    test('beberapa calon → durasi paling dekat', () {
      expect(matchTracks([_t('Halo', ['Beyoncé'], ms: 212000)], lib).songIds, [7]);
    });

    test('gak ada di HP → belum punya, urutan tetap', () {
      final r = matchTracks([
        _t('Unknown Song', ['Nobody']),
        _t('Animals', ['Maroon 5']),
        _t('Burn', ['Taylor Swift']),
      ], lib);
      expect(r.songIds, [1]);
      expect([for (final m in r.missing) m.title], ['Unknown Song', 'Burn']);
    });
  });
}
