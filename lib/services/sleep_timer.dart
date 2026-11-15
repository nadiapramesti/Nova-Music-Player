import 'dart:async';

import 'package:flutter/foundation.dart';

/// Timer tidur: berhenti otomatis setelah durasi tertentu, atau di akhir lagu.
/// Volume diturunin pelan di [fade] terakhir biar gak kaget, lalu dibalikin
/// ke 100% setelah musik dijeda.
///
/// Gak tergantung ke AudioPlayer langsung (lewat [pause] & [setVolume]),
/// jadi bisa dites tanpa HP.
class SleepTimer {
  SleepTimer({
    required this.pause,
    required this.setVolume,
    DateTime Function()? now,
    this.fade = const Duration(seconds: 8),
  }) : _now = now ?? DateTime.now;

  final FutureOr<void> Function() pause;
  final FutureOr<void> Function(double volume) setVolume;
  final DateTime Function() _now;
  final Duration fade;

  /// Sisa waktu; null = timer menit gak aktif.
  final ValueNotifier<Duration?> left = ValueNotifier<Duration?>(null);

  /// true = berhenti pas lagu sekarang selesai.
  final ValueNotifier<bool> endOfTrack = ValueNotifier<bool>(false);

  DateTime? _endsAt;
  Timer? _ticker;
  bool _volumeLowered = false;

  bool get active => left.value != null || endOfTrack.value;

  Listenable get listenable => Listenable.merge([left, endOfTrack]);

  /// Mulai hitung mundur.
  void start(Duration duration) {
    cancel();
    _endsAt = _now().add(duration);
    left.value = duration;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  /// Berhenti di akhir lagu yang lagi diputar.
  void startEndOfTrack() {
    cancel();
    endOfTrack.value = true;
  }

  /// Dipanggil tiap lagu selesai / pindah otomatis ke lagu berikutnya.
  void onTrackEnded() {
    if (!endOfTrack.value) return;
    _fire();
  }

  /// Dipanggil tiap detik oleh ticker (publik buat test).
  void tick() {
    final endsAt = _endsAt;
    if (endsAt == null) return;
    final remaining = endsAt.difference(_now());
    if (remaining <= Duration.zero) {
      _fire();
      return;
    }
    left.value = remaining;
    if (remaining <= fade) {
      _volumeLowered = true;
      setVolume((remaining.inMilliseconds / fade.inMilliseconds).clamp(0.0, 1.0));
    }
  }

  Future<void> _fire() async {
    _stopTicker();
    left.value = null;
    endOfTrack.value = false;
    await pause();
    await _restoreVolume();
  }

  /// Matikan timer (volume dibalikin kalau sempat diturunin).
  void cancel() {
    _stopTicker();
    left.value = null;
    endOfTrack.value = false;
    _restoreVolume();
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;
  }

  Future<void> _restoreVolume() async {
    if (!_volumeLowered) return;
    _volumeLowered = false;
    await setVolume(1.0);
  }

  void dispose() {
    _stopTicker();
    left.dispose();
    endOfTrack.dispose();
  }
}

/// "12:05" / "1:02:05" buat hitung mundur.
String formatCountdown(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
