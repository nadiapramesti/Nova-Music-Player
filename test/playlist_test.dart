import 'package:flutter_test/flutter_test.dart';
import 'package:nova/demo/demo_data.dart';
import 'package:nova/services/playlist_service.dart';

void main() {
  test('nama playlist dirapikan', () {
    expect(cleanPlaylistName('  Lagu   buat nyetir  '), 'Lagu buat nyetir');
    expect(cleanPlaylistName('   '), isNull);
    expect(cleanPlaylistName('a' * 60)!.length, 40);
  });

  test('simpan & baca ulang playlist (JSON)', () {
    final items = [
      Playlist(id: '1', name: 'Pagi', songIds: [101, 102], createdAt: 5),
      Playlist(id: '2', name: 'Malam'),
    ];
    final back = decodePlaylists(encodePlaylists(items));
    expect(back.length, 2);
    expect(back.first.name, 'Pagi');
    expect(back.first.songIds, [101, 102]);
    expect(back.first.createdAt, 5);
    expect(back[1].songIds, isEmpty);
  });

  test('data rusak gak bikin crash', () {
    expect(decodePlaylists(null), isEmpty);
    expect(decodePlaylists('bukan json'), isEmpty);
    expect(decodePlaylists('{"a":1}'), isEmpty);
    expect(decodePlaylists('[{"id":1}, {"id":"x","name":"Ok","songs":[1,"2",3]}]').single.songIds, [1, 3]);
  });

  test('tambah, cegah dobel, hapus, urutan lagu, lagu hilang dilewati', () {
    final svc = PlaylistService();
    final p = svc.create('Nyetir')!;
    final songs = demoSongs();
    svc.add(p.id, songs[3].id);
    svc.add(p.id, songs[1].id);
    svc.add(p.id, songs[3].id); // dobel
    expect(svc.byId(p.id)!.songIds, [songs[3].id, songs[1].id]);

    svc.add(p.id, 999999); // lagu yang udah gak ada di HP
    expect(svc.songsOf(p.id, songs).map((s) => s.id), [songs[3].id, songs[1].id]);

    svc.toggle(p.id, songs[3].id);
    expect(svc.contains(p.id, songs[3].id), isFalse);

    expect(svc.rename(p.id, '  '), isFalse);
    expect(svc.rename(p.id, 'Nyetir malam'), isTrue);
    expect(svc.byId(p.id)!.name, 'Nyetir malam');

    svc.delete(p.id);
    expect(svc.items, isEmpty);
  });

  test('playlist baru muncul paling atas', () {
    final svc = PlaylistService();
    svc.create('Satu');
    svc.create('Dua');
    expect(svc.items.map((p) => p.name), ['Dua', 'Satu']);
    expect(svc.create(''), isNull);
  });
}
