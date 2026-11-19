import 'package:flutter_test/flutter_test.dart';
import 'package:nova/models.dart';
import 'package:nova/services/resume.dart';

Song _s(int id, {int ms = 200000}) => Song(
      id: id,
      title: 'Lagu $id',
      artist: 'A',
      album: 'X',
      albumId: 1,
      durationMs: ms,
      dateAdded: id,
      path: '/m/$id.mp3',
      uri: 'content://x/$id',
    );

Map<int, Song> _lib(List<int> ids) => {for (final i in ids) i: _s(i)};

void main() {
  group('ResumeState', () {
    test('simpan & baca bolak-balik', () {
      const st = ResumeState(ids: [3, 1, 2], index: 1, positionMs: 45000, from: 'Playlist · Malam', shuffle: true, loop: 'one');
      final back = ResumeState.decode(st.encode())!;
      expect(back.ids, [3, 1, 2]);
      expect(back.index, 1);
      expect(back.positionMs, 45000);
      expect(back.from, 'Playlist · Malam');
      expect(back.shuffle, isTrue);
      expect(back.loop, 'one');
    });

    test('data rusak → null', () {
      expect(ResumeState.decode(null), isNull);
      expect(ResumeState.decode(''), isNull);
      expect(ResumeState.decode('{x'), isNull);
      expect(ResumeState.decode('{"ids":[],"i":0}'), isNull);
      expect(ResumeState.decode('{"ids":[1,2],"i":"a"}'), isNull);
    });

    test('index kelewat batas dijepit, loop aneh jadi off', () {
      final st = ResumeState.decode('{"ids":[1,2],"i":9,"loop":"lol"}')!;
      expect(st.index, 1);
      expect(st.loop, 'off');
    });
  });

  group('restoreQueue', () {
    test('utuh: lagu & detik sama', () {
      final r = restoreQueue(const ResumeState(ids: [1, 2, 3], index: 1, positionMs: 30000), _lib([1, 2, 3]))!;
      expect([for (final s in r.songs) s.id], [1, 2, 3]);
      expect(r.index, 1);
      expect(r.position, const Duration(seconds: 30));
    });

    test('lagu lain yang hilang dibuang, index ikut geser', () {
      final r = restoreQueue(const ResumeState(ids: [1, 2, 3, 4], index: 2, positionMs: 1000), _lib([2, 3, 4]))!;
      expect([for (final s in r.songs) s.id], [2, 3, 4]);
      expect(r.index, 1);
      expect(r.songs[r.index].id, 3);
    });

    test('lagu terakhir hilang → lanjut lagu berikutnya dari awal', () {
      final r = restoreQueue(const ResumeState(ids: [1, 2, 3], index: 1, positionMs: 50000), _lib([1, 3]))!;
      expect(r.songs[r.index].id, 3);
      expect(r.position, Duration.zero);
    });

    test('lagu terakhir paling ujung & hilang → balik ke awal antrean', () {
      final r = restoreQueue(const ResumeState(ids: [1, 2, 3], index: 2), _lib([1, 2]))!;
      expect(r.index, 0);
    });

    test('detik di ujung lagu → mulai dari awal', () {
      final r = restoreQueue(const ResumeState(ids: [1], index: 0, positionMs: 199000), _lib([1]))!;
      expect(r.position, Duration.zero);
    });

    test('semua hilang → null', () {
      expect(restoreQueue(const ResumeState(ids: [1, 2], index: 0), {}), isNull);
    });
  });
}
