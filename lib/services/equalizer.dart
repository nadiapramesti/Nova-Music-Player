import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../demo/demo.dart';

/// Preset EQ: titik (frekuensi Hz, gain dB). Di antara titik diisi mulus (skala log).
const eqPresets = <String, List<(double, double)>>{
  'Normal': [(60, 0), (16000, 0)],
  'Bass': [(60, 6), (150, 4.5), (400, 1), (1000, 0), (16000, 0)],
  'Vokal': [(60, -2), (250, -1), (1000, 2.5), (3000, 4), (8000, 1.5), (16000, 0)],
  'Akustik': [(60, 3), (250, 1.5), (1000, 0.5), (3000, 2), (8000, 3), (16000, 2)],
  'Treble': [(60, 0), (1000, 0), (3000, 2.5), (8000, 5), (16000, 6)],
  'Malam': [(60, 2), (250, 1), (1000, 0), (4000, -2), (16000, -4)],
};

/// Gain dB tiap band (pakai frekuensi tengahnya) dari preset, dijepit ke batas HP.
List<double> presetGains(String preset, List<double> centersHz, double minDb, double maxDb) {
  final pts = eqPresets[preset] ?? eqPresets['Normal']!;
  double at(double hz) {
    if (hz <= pts.first.$1) return pts.first.$2;
    if (hz >= pts.last.$1) return pts.last.$2;
    for (var i = 0; i < pts.length - 1; i++) {
      final (f0, g0) = pts[i];
      final (f1, g1) = pts[i + 1];
      if (hz >= f0 && hz <= f1) {
        final t = (log(hz) - log(f0)) / (log(f1) - log(f0));
        return g0 + (g1 - g0) * t;
      }
    }
    return 0;
  }

  return [for (final c in centersHz) at(c).clamp(minDb, maxDb)];
}

/// Label frekuensi pendek: 60, 230, 1k, 3,6k, 14k.
String hzLabel(double hz) {
  if (hz < 1000) return hz.round().toString();
  final k = hz / 1000;
  return k >= 10 || k == k.roundToDouble() ? '${k.round()}k' : '${k.toStringAsFixed(1).replaceAll('.', ',')}k';
}

class EqSettings {
  const EqSettings({this.enabled = false, this.preset = 'Normal', this.custom});
  final bool enabled;

  /// Nama preset, atau 'Custom' kalau band diatur manual.
  final String preset;
  final List<double>? custom;

  String encode() => jsonEncode({'on': enabled, 'p': preset, if (custom != null) 'c': custom});

  static EqSettings decode(String? raw) {
    if (raw == null) return const EqSettings();
    try {
      final m = jsonDecode(raw) as Map;
      final c = (m['c'] as List?)?.whereType<num>().map((e) => e.toDouble()).toList();
      final p = m['p'] is String ? m['p'] as String : 'Normal';
      return EqSettings(
        enabled: m['on'] == true,
        preset: p == 'Custom' || eqPresets.containsKey(p) ? p : 'Normal',
        custom: c,
      );
    } catch (_) {
      return const EqSettings();
    }
  }
}

/// Equalizer Android yang nempel ke pemutar Nova.
class EqService extends ChangeNotifier {
  final AndroidEqualizer eq = AndroidEqualizer();

  EqSettings settings = const EqSettings();
  AndroidEqualizerParameters? params;

  Future<void> init() async {
    settings = EqSettings.decode((await SharedPreferences.getInstance()).getString('eq'));
  }

  /// Ambil info band dari HP (baru ada setelah pemutar siap) lalu terapkan setelan.
  Future<AndroidEqualizerParameters?> ready() async {
    if (kDemo || defaultTargetPlatform != TargetPlatform.android) return null;
    if (params != null) return params;
    try {
      params = await eq.parameters.timeout(const Duration(seconds: 4));
      await _apply();
      notifyListeners();
    } catch (_) {}
    return params;
  }

  List<double> get gains {
    final p = params;
    if (p == null) return const [];
    final c = settings.custom;
    if (settings.preset == 'Custom' && c != null && c.length == p.bands.length) return c;
    return presetGains(settings.preset, [for (final b in p.bands) b.centerFrequency], p.minDecibels, p.maxDecibels);
  }

  Future<void> setEnabled(bool v) => _update(EqSettings(enabled: v, preset: settings.preset, custom: settings.custom));

  Future<void> setPreset(String preset) => _update(EqSettings(enabled: true, preset: preset, custom: settings.custom));

  Future<void> setBand(int index, double db) {
    final g = List<double>.from(gains);
    if (index < 0 || index >= g.length) return Future.value();
    g[index] = db;
    return _update(EqSettings(enabled: true, preset: 'Custom', custom: g));
  }

  Future<void> _update(EqSettings next) async {
    settings = next;
    notifyListeners();
    await _apply();
    (await SharedPreferences.getInstance()).setString('eq', next.encode());
  }

  Future<void> _apply() async {
    final p = params;
    if (p == null) return;
    try {
      final g = gains;
      for (var i = 0; i < p.bands.length && i < g.length; i++) {
        await p.bands[i].setGain(settings.enabled ? g[i] : 0);
      }
      await eq.setEnabled(settings.enabled);
    } catch (_) {}
  }
}
