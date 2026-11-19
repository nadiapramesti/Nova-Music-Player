import 'package:flutter_test/flutter_test.dart';
import 'package:nova/services/backup.dart';

void main() {
  test('cadangan bolak-balik utuh, cuma kunci Nova yang ikut', () {
    final raw = buildBackup({
      'fav': ['1', '2'],
      'playlists': '[{"id":"a","name":"Nyetir","ids":[1]}]',
      'fadeSeconds': 4,
      'accentFromCover': false,
      'resume': '{"ids":[1]}', // bukan kunci cadangan
      'aneh': 'x',
      'counts': {'gak': 'valid'}, // tipe aneh dilewatin
    }, now: DateTime(2026, 11, 19));
    final back = parseBackup(raw)!;
    expect(back['fav'], ['1', '2']);
    expect(back['fadeSeconds'], 4);
    expect(back['accentFromCover'], false);
    expect(back.containsKey('resume'), isFalse);
    expect(back.containsKey('aneh'), isFalse);
    expect(back.containsKey('counts'), isFalse);
  });

  test('bukan file Nova / rusak → null', () {
    expect(parseBackup('halo'), isNull);
    expect(parseBackup('{"format":"lain","data":{}}'), isNull);
    expect(parseBackup('{"format":"nova-backup","data":[]}'), isNull);
  });

  test('kunci asing di file dibuang, list campur dibuang', () {
    final back = parseBackup('{"format":"nova-backup","data":{"fav":["1",2],"recent":["a"],"hack":"x"}}')!;
    expect(back.keys, ['recent']);
  });

  test('ringkasan', () {
    final s = summarizeBackup({
      'fav': ['1', '2', '3'],
      'playlists': '[{"id":"a"},{"id":"b"}]',
      'songEdits': '{"5":{"t":"A"}}',
    });
    expect(s.favorites, 3);
    expect(s.playlists, 2);
    expect(s.edits, 1);
  });
}
