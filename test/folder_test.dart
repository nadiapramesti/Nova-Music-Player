import 'package:flutter_test/flutter_test.dart';
import 'package:nova/models.dart';

Song song(int id, String path) => Song(
      id: id,
      title: 'Lagu $id',
      artist: 'A',
      album: 'B',
      albumId: 1,
      durationMs: 180000,
      dateAdded: 0,
      path: path,
      uri: 'content://$id',
    );

void main() {
  final songs = [
    song(1, '/storage/emulated/0/Music/Pop/a.mp3'),
    song(2, '/storage/emulated/0/Music/Pop/b.mp3'),
    song(3, '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio/c.opus'),
    song(4, '/storage/emulated/0/Download/Music/d.mp3'),
    song(5, '/storage/emulated/0/Music/Pop/Live/e.mp3'),
  ];

  test('path folder lengkap', () {
    expect(songs.first.folderPath, '/storage/emulated/0/Music/Pop');
    expect(songs.first.folder, 'Pop');
  });

  test('folder tersembunyi (plus subfolder-nya) dibuang', () {
    final out = withoutHiddenFolders(songs, {'/storage/emulated/0/Music/Pop'});
    expect(out.map((s) => s.id), [3, 4]);
  });

  test('nama sama beda tempat gak ikut kesembunyi', () {
    final out = withoutHiddenFolders(songs, {'/storage/emulated/0/Download/Music'});
    expect(out.map((s) => s.id), [1, 2, 3, 5]);
  });

  test('awalan mirip bukan subfolder ("Pop" vs "Pop Lama")', () {
    final s = [song(9, '/x/Pop Lama/z.mp3')];
    expect(withoutHiddenFolders(s, {'/x/Pop'}).length, 1);
  });

  test('ringkasan folder: hitung lagu, urut nama', () {
    final sum = folderSummary(songs);
    expect(sum.map((f) => f.$2), ['Live', 'Music', 'Pop', 'WhatsApp Audio']);
    expect(sum.firstWhere((f) => f.$2 == 'Pop').$3, 2);
  });

  test('tanpa folder tersembunyi: daftar utuh', () {
    expect(withoutHiddenFolders(songs, {}).length, 5);
  });
}
