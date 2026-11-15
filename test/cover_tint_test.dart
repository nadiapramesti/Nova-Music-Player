import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/services/cover_tint.dart';
import 'package:nova/theme.dart';

Uint8List _pixels(List<(Color, int)> parts) {
  final out = <int>[];
  for (final (c, n) in parts) {
    for (var i = 0; i < n; i++) {
      out.addAll([(c.r * 255).round(), (c.g * 255).round(), (c.b * 255).round(), 255]);
    }
  }
  return Uint8List.fromList(out);
}

double _hue(Color c) => HSLColor.fromColor(c).hue;

void main() {
  group('vibrantFromRgba', () {
    test('cover merah dominan → warna merah', () {
      final c = vibrantFromRgba(_pixels([(const Color(0xFFD02020), 700), (const Color(0xFF202020), 324)]))!;
      final h = _hue(c);
      expect(h < 20 || h > 340, isTrue, reason: 'hue $h');
    });

    test('warna yang paling luas menang, bukan yang paling terang', () {
      final c = vibrantFromRgba(_pixels([
        (const Color(0xFF1E8C4A), 600), // hijau, banyak
        (const Color(0xFFFF3030), 120), // merah terang, sedikit
        (const Color(0xFF101010), 300),
      ]))!;
      expect(_hue(c), inInclusiveRange(120, 160));
    });

    test('cover hitam-putih → null (pakai biru Nova)', () {
      expect(vibrantFromRgba(_pixels([(const Color(0xFF000000), 500), (const Color(0xFFFFFFFF), 300), (const Color(0xFF808080), 224)])), isNull);
    });

    test('warna cuma secuil di cover gelap → null', () {
      expect(vibrantFromRgba(_pixels([(const Color(0xFF0A0A0A), 1000), (const Color(0xFF3060FF), 20)])), isNull);
    });

    test('piksel transparan diabaikan, data kosong aman', () {
      expect(vibrantFromRgba(Uint8List.fromList([255, 0, 0, 0, 0, 255, 0, 10])), isNull);
      expect(vibrantFromRgba(Uint8List(0)), isNull);
    });
  });

  test('vibrantFromColors pilih yang paling hidup, abaikan abu', () {
    expect(vibrantFromColors([const Color(0xFF777777), const Color(0xFF2050E0), const Color(0xFF203050)]), const Color(0xFF2050E0));
    expect(vibrantFromColors([const Color(0xFF777777), const Color(0xFF111111)]), isNull);
  });

  group('tuneAccent', () {
    test('gelap: selalu terang & hue tetap', () {
      for (final raw in [const Color(0xFF400000), const Color(0xFF00FF00), const Color(0xFF101060)]) {
        final a = tuneAccent(raw, Brightness.dark);
        expect(HSLColor.fromColor(a).lightness, closeTo(0.76, 0.01));
        expect(_hue(a), closeTo(_hue(raw), 1.5));
        // Kontras sama latar gelap Nova cukup buat teks.
        expect(a.computeLuminance(), greaterThan(0.3));
      }
    });

    test('terang: aksen cukup gelap buat teks putih di atasnya', () {
      final a = tuneAccent(const Color(0xFF3060FF), Brightness.light);
      expect(HSLColor.fromColor(a).lightness, closeTo(0.4, 0.01));
      expect(onAccentFor(a, Brightness.light), const Color(0xFFFFFFFF));
    });

    test('onAccent gelap tetap gelap', () {
      final on = onAccentFor(tuneAccent(const Color(0xFFFFCC00), Brightness.dark), Brightness.dark);
      expect(on.computeLuminance(), lessThan(0.05));
    });
  });

  test('withAccent cuma ganti warna aksen', () {
    final p = Palette.dark.withAccent(const Color(0xFFFF8800), const Color(0xFF221100));
    expect(p.accent, const Color(0xFFFF8800));
    expect(p.bg, Palette.dark.bg);
    expect(p.text, Palette.dark.text);
    expect((p.glow.a * 255).round(), (Palette.dark.glow.a * 255).round());
    expect(p.glow.withAlpha(255), const Color(0xFFFF8800));
  });
}
