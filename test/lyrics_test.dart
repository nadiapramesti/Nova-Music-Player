import 'package:flutter_test/flutter_test.dart';
import 'package:nova/services/lyrics.dart';

void main() {
  test('LRC dasar: waktu, metadata dibuang, urut', () {
    final l = parseLrc('''
[ti:Judul]
[ar:Artis]
[00:12.50]Baris dua
[00:01.00]Baris satu
[01:02.345]Baris tiga
''')!;
    expect(l.synced, isTrue);
    expect(l.lines.map((e) => e.text), ['Baris satu', 'Baris dua', 'Baris tiga']);
    expect(l.lines[1].time, const Duration(seconds: 12, milliseconds: 500));
    expect(l.lines[2].time, const Duration(minutes: 1, seconds: 2, milliseconds: 345));
  });

  test('banyak timestamp di satu baris (reff)', () {
    final l = parseLrc('[00:10.00][00:40.00]Reff\n[00:20.00]Bait')!;
    expect(l.lines.map((e) => e.text), ['Reff', 'Bait', 'Reff']);
    expect(l.lines.last.time, const Duration(seconds: 40));
  });

  test('format [mm:ss:xx] dan [mm:ss] tanpa pecahan', () {
    final l = parseLrc('[00:05:20]A\n[00:07]B')!;
    expect(l.lines[0].time, const Duration(seconds: 5, milliseconds: 200));
    expect(l.lines[1].time, const Duration(seconds: 7));
  });

  test('offset: positif = lirik lebih awal, gak bisa minus', () {
    final l = parseLrc('[offset:+500]\n[00:01.00]A\n[00:00.20]B')!;
    expect(l.lines.map((e) => e.time), [Duration.zero, const Duration(milliseconds: 500)]);
  });

  test('teks tanpa timestamp = lirik biasa, baris kosong dirapikan', () {
    final l = parseLrc('\n\nBaris satu\n\n\nBaris dua\n\n', source: 'tertanam di lagu')!;
    expect(l.synced, isFalse);
    expect(l.lines.map((e) => e.text), ['Baris satu', '', 'Baris dua']);
    expect(l.indexAt(const Duration(seconds: 5)), -1);
  });

  test('kosong / cuma metadata = null', () {
    expect(parseLrc(''), isNull);
    expect(parseLrc('[ti:x]\n[ar:y]'), isNull);
  });

  test('BOM & CRLF', () {
    final l = parseLrc('﻿[00:01.00]A\r\n[00:02.00]B\r\n')!;
    expect(l.lines.length, 2);
  });

  test('baris aktif sesuai posisi', () {
    final l = parseLrc('[00:01.00]A\n[00:05.00]B\n[00:09.00]C')!;
    expect(l.indexAt(Duration.zero), -1);
    expect(l.indexAt(const Duration(seconds: 1)), 0);
    expect(l.indexAt(const Duration(seconds: 7)), 1);
    expect(l.indexAt(const Duration(minutes: 3)), 2);
  });
}
