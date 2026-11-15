import 'package:flutter_test/flutter_test.dart';
import 'package:nova/models.dart';
import 'package:nova/services/song_edits.dart';

Song _song(int id, {String title = 'Asli', String artist = 'Artis', String album = 'Album'}) => Song(
      id: id,
      title: title,
      artist: artist,
      album: album,
      albumId: 7,
      durationMs: 200000,
      dateAdded: 1,
      path: '/Music/$id.mp3',
      uri: 'content://x/$id',
    );

void main() {
  group('cleanEdit', () {
    final s = _song(1);

    test('sama dengan asli atau kosong → gak diubah', () {
      expect(cleanEdit(s, title: 'Asli', artist: '  ', album: 'Album').isEmpty, isTrue);
    });

    test('spasi dirapikan', () {
      final e = cleanEdit(s, title: '  Judul   Baru ', artist: 'Artis', album: '');
      expect(e.title, 'Judul Baru');
      expect(e.artist, isNull);
      expect(e.album, isNull);
    });

    test('kepanjangan dipotong 120 huruf', () {
      expect(cleanEdit(s, title: 'a' * 300, artist: '', album: '').title!.length, 120);
    });
  });

  group('applyEdits', () {
    test('cuma lagu yang diubah yang berubah, sisanya utuh', () {
      final songs = [_song(1), _song(2)];
      final out = applyEdits(songs, {2: const SongEdit(artist: 'Baru')});
      expect(identical(out[0], songs[0]), isTrue);
      expect(out[1].artist, 'Baru');
      expect(out[1].title, 'Asli');
      expect(out[1].path, songs[1].path);
      expect(out[1].albumId, 7);
    });

    test('tanpa perubahan → list yang sama', () {
      final songs = [_song(1)];
      expect(identical(applyEdits(songs, {}), songs), isTrue);
    });
  });

  group('simpan & baca', () {
    test('bolak-balik utuh, yang kosong gak disimpan', () {
      final raw = encodeEdits({
        5: const SongEdit(title: 'A', album: 'B'),
        6: const SongEdit(),
      });
      final back = decodeEdits(raw);
      expect(back.keys, [5]);
      expect(back[5], const SongEdit(title: 'A', album: 'B'));
    });

    test('data rusak gak bikin crash', () {
      expect(decodeEdits(null), isEmpty);
      expect(decodeEdits(''), isEmpty);
      expect(decodeEdits('{rusak'), isEmpty);
      expect(decodeEdits('[1,2]'), isEmpty);
      expect(decodeEdits('{"x":{"t":"A"},"3":"bukan map","4":{"t":"  "},"9":{"a":"Ok"}}').keys, [9]);
    });
  });

  test('copyWith null = tetap', () {
    final s = _song(1);
    final c = s.copyWith();
    expect(c.title, s.title);
    expect(c.uri, s.uri);
  });
}
