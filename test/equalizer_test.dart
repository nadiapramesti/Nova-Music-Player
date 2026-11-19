import 'package:flutter_test/flutter_test.dart';
import 'package:nova/services/equalizer.dart';

void main() {
  const centers = [60.0, 230.0, 910.0, 3600.0, 14000.0];

  test('Normal = datar', () {
    expect(presetGains('Normal', centers, -15, 15), everyElement(0));
  });

  test('Bass: rendah naik, tinggi datar', () {
    final g = presetGains('Bass', centers, -15, 15);
    expect(g.first, 6);
    expect(g[1], inExclusiveRange(1, 6));
    expect(g.last, 0);
  });

  test('dijepit ke batas HP', () {
    final g = presetGains('Treble', centers, -3, 3);
    expect(g.every((v) => v >= -3 && v <= 3), isTrue);
    expect(g.last, 3);
  });

  test('preset gak dikenal → datar', () {
    expect(presetGains('Ngawur', centers, -15, 15), everyElement(0));
  });

  test('label frekuensi', () {
    expect(hzLabel(60), '60');
    expect(hzLabel(910), '910');
    expect(hzLabel(1000), '1k');
    expect(hzLabel(3600), '3,6k');
    expect(hzLabel(14000), '14k');
  });

  test('setelan bolak-balik & data rusak aman', () {
    final s = EqSettings.decode(const EqSettings(enabled: true, preset: 'Custom', custom: [1, 2, 3]).encode());
    expect(s.enabled, isTrue);
    expect(s.preset, 'Custom');
    expect(s.custom, [1, 2, 3]);
    expect(EqSettings.decode('rusak').preset, 'Normal');
    expect(EqSettings.decode('{"p":"Hantu"}').preset, 'Normal');
  });
}
