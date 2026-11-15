import 'dart:async';
import 'dart:math';

/// Volume (0..1) buat transisi halus antar lagu: pelan naik di awal lagu,
/// pelan turun di [fade] terakhir. Lagu yang pendek banget gak di-fade-out
/// biar gak keburu habis cuma buat transisi.
double transitionGain({required Duration pos, required Duration? dur, required Duration fade}) {
  if (fade <= Duration.zero) return 1;
  var g = 1.0;

  // Naik lebih cepat dari turunnya: setengah durasi, maks 2 detik.
  final fadeInMs = min(fade.inMilliseconds ~/ 2, 2000);
  if (fadeInMs > 0 && pos.inMilliseconds < fadeInMs) {
    g = min(g, _curve(pos.inMilliseconds / fadeInMs));
  }

  if (dur != null && dur > fade * 3) {
    final left = dur - pos;
    if (left < fade) g = min(g, _curve(left.inMilliseconds / fade.inMilliseconds));
  }
  return g.clamp(0.0, 1.0);
}

/// Kurva "equal power": kedengeran lebih rata daripada garis lurus.
double _curve(double t) => sin(t.clamp(0.0, 1.0) * pi / 2);

/// Gabungan volume dari timer tidur & transisi, biar gak saling timpa.
/// Cuma kirim ke player kalau nilainya beneran berubah (dibulatkan 1%).
class VolumeMixer {
  VolumeMixer(this._set);
  final FutureOr<void> Function(double volume) _set;

  double _sleep = 1, _fade = 1;
  double _last = -1;

  double get value => _sleep * _fade;

  void setSleep(double v) {
    _sleep = v.clamp(0.0, 1.0);
    _push();
  }

  void setFade(double v) {
    _fade = v.clamp(0.0, 1.0);
    _push();
  }

  void _push() {
    final v = (value * 100).round() / 100;
    if (v == _last) return;
    _last = v;
    _set(v);
  }
}

/// Pilihan durasi transisi di pengaturan (0 = mati).
const transitionChoices = [0, 2, 4, 6];
