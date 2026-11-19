import 'package:flutter_test/flutter_test.dart';
import 'package:nova/models.dart';

Song _s(int id, String title, [String artist = 'A']) => Song(
      id: id,
      title: title,
      artist: artist,
      album: 'X',
      albumId: 1,
      durationMs: 200000,
      dateAdded: id,
      path: '/m/$id.mp3',
      uri: 'content://x/$id',
    );

List<String> _titles(List<Song> l) => [for (final s in l) s.title];

void main() {
  test('A–Z gak peduli huruf besar/kecil', () {
    expect(_titles(sortAz([_s(1, 'banyu'), _s(2, 'Angin'), _s(3, 'cahaya')])), ['Angin', 'banyu', 'cahaya']);
  });

  test('tanda baca di depan diabaikan', () {
    expect(_titles(sortAz([_s(1, 'Zebra'), _s(2, '(Live) Bulan'), _s(3, '"Awan"')])), ['"Awan"', '(Live) Bulan', 'Zebra']);
  });

  test('angka diurut sebagai angka', () {
    expect(_titles(sortAz([_s(1, 'Track 10'), _s(2, 'Track 2'), _s(3, 'Track 1')])), ['Track 1', 'Track 2', 'Track 10']);
  });

  test('judul sama → urut artis, list asli gak berubah', () {
    final src = [_s(1, 'Pulang', 'Zia'), _s(2, 'Pulang', 'Bima')];
    final out = sortAz(src);
    expect([for (final s in out) s.artist], ['Bima', 'Zia']);
    expect(src.first.artist, 'Zia');
  });
}
