import 'package:flutter_test/flutter_test.dart';
import 'package:nova/services/transition.dart';

void main() {
  const fade = Duration(seconds: 4);
  const dur = Duration(minutes: 3);
  double g(int ms, {Duration? d = dur, Duration f = fade}) =>
      transitionGain(pos: Duration(milliseconds: ms), dur: d, fade: f);

  group('transitionGain', () {
    test('mati → selalu penuh', () {
      expect(g(0, f: Duration.zero), 1);
      expect(g(179900, f: Duration.zero), 1);
    });

    test('awal lagu naik pelan (setengah durasi fade)', () {
      expect(g(0), 0);
      expect(g(1000), inExclusiveRange(0.5, 0.9));
      expect(g(2000), 1);
      expect(g(60000), 1);
    });

    test('akhir lagu turun pelan', () {
      expect(g(176000), closeTo(1, 0.001));
      expect(g(178000), inExclusiveRange(0.5, 0.9));
      expect(g(180000), 0);
      expect(g(182000), 0, reason: 'posisi lewat durasi gak bikin negatif');
    });

    test('naik maks 2 detik walau fade panjang', () {
      expect(g(2000, f: const Duration(seconds: 10)), 1);
    });

    test('durasi belum diketahui → cuma fade-in', () {
      expect(g(60000, d: null), 1);
    });

    test('lagu pendek banget gak di-fade-out', () {
      const short = Duration(seconds: 10);
      expect(g(9000, d: short), 1);
    });

    test('kurva naik terus (gak loncat)', () {
      var prev = -1.0;
      for (var ms = 0; ms <= 2000; ms += 100) {
        final v = g(ms);
        expect(v, greaterThanOrEqualTo(prev));
        prev = v;
      }
    });
  });

  group('VolumeMixer', () {
    test('timer tidur × transisi dikalikan', () {
      final sent = <double>[];
      final m = VolumeMixer(sent.add);
      m.setFade(0.5);
      m.setSleep(0.5);
      expect(m.value, 0.25);
      expect(sent.last, 0.25);
      m.setSleep(1);
      expect(sent.last, 0.5);
    });

    test('gak kirim ulang kalau nilainya sama', () {
      final sent = <double>[];
      final m = VolumeMixer(sent.add);
      m.setFade(1);
      m.setFade(1);
      m.setFade(0.999);
      expect(sent, [1.0]);
    });

    test('nilai di luar 0..1 dijepit', () {
      final sent = <double>[];
      final m = VolumeMixer(sent.add)..setFade(3);
      expect(sent.last, 1);
      m.setSleep(-2);
      expect(sent.last, 0);
    });
  });

  test('pilihan durasi diawali "mati"', () {
    expect(transitionChoices.first, 0);
  });
}
