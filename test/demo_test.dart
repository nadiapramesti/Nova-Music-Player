import 'package:flutter_test/flutter_test.dart';
import 'package:nova/demo/demo_data.dart';
import 'package:nova/demo/silent_source.dart';
import 'package:nova/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('data demo', () {
    final songs = demoSongs(now: DateTime(2026, 11, 15));

    test('cukup banyak lagu, ID unik', () {
      expect(songs.length, greaterThanOrEqualTo(15));
      expect(songs.map((s) => s.id).toSet().length, songs.length);
    });

    test('album & artis terisi', () {
      expect(songs.map((s) => s.album).toSet().length, greaterThanOrEqualTo(5));
      expect(songs.map((s) => s.artist).toSet().length, greaterThanOrEqualTo(5));
    });

    test('durasi masuk akal (2,5–5,5 menit) dan judul gak kosong', () {
      for (final s in songs) {
        expect(s.durationMs, inInclusiveRange(150000, 330000), reason: s.title);
        expect(s.title.trim(), isNotEmpty);
        expect(s.artist.trim(), isNotEmpty);
      }
    });

    test('tiap lagu punya cover demo', () {
      for (final s in songs) {
        expect(demoAlbumOfSong(s.id), isNotNull, reason: s.title);
      }
    });

    test('ada lagu baru minggu ini (pintasan "Baru masuk HP" gak kosong)', () {
      final cutoff = DateTime(2026, 11, 8).millisecondsSinceEpoch ~/ 1000;
      expect(songs.where((s) => s.dateAdded >= cutoff), isNotEmpty);
    });
  });

  group('audio senyap', () {
    test('header WAV valid & panjang sesuai durasi', () async {
      final src = SilentAudioSource(durationMs: 2000);
      final res = await src.request(0, 44);
      final bytes = (await res.stream.toList()).expand((b) => b).toList();
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');
      expect(res.sourceLength, 44 + 2000 * 8);
    });

    test('potongan tengah isinya hening (128)', () async {
      final src = SilentAudioSource(durationMs: 1000);
      final res = await src.request(100, 200);
      final bytes = (await res.stream.toList()).expand((b) => b).toList();
      expect(bytes.length, 100);
      expect(bytes.every((b) => b == 128), isTrue);
    });
  });

  test('palet bisa pindah gelap ↔ terang', () {
    expect(Nv.isLight, isFalse);
    setPalette(Palette.light);
    expect(Nv.isLight, isTrue);
    expect(Nv.bg, Palette.light.bg);
    setPalette(Palette.dark);
    expect(Nv.bg, Palette.dark.bg);
  });
}
