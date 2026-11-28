import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../demo/demo.dart';
import '../demo/demo_data.dart';
import '../models.dart';
import '../theme.dart';
import 'library_service.dart';
import 'player_service.dart';

/// Warna paling "hidup" dari piksel RGBA (dari cover yang diperkecil).
/// Balikin null kalau cover-nya hampir hitam-putih, biar tetap pakai biru Nova.
Color? vibrantFromRgba(Uint8List rgba) {
  const bins = 12; // tiap 30° hue
  final weight = List<double>.filled(bins, 0);
  final sumR = List<double>.filled(bins, 0);
  final sumG = List<double>.filled(bins, 0);
  final sumB = List<double>.filled(bins, 0);
  var counted = 0;

  for (var i = 0; i + 3 < rgba.length; i += 4) {
    if (rgba[i + 3] < 128) continue;
    counted++;
    final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
    final hsv = HSVColor.fromColor(Color.fromARGB(255, r, g, b));
    // Abu-abu, hampir hitam, atau hampir putih gak dihitung.
    if (hsv.saturation < 0.2 || hsv.value < 0.18) continue;
    final w = hsv.saturation * hsv.value;
    final bin = (hsv.hue / (360 / bins)).floor() % bins;
    weight[bin] += w;
    sumR[bin] += r * w;
    sumG[bin] += g * w;
    sumB[bin] += b * w;
  }
  if (counted == 0) return null;

  var best = 0;
  for (var i = 1; i < bins; i++) {
    if (weight[i] > weight[best]) best = i;
  }
  final total = weight.fold<double>(0, (a, b) => a + b);
  // Warna cuma secuil (mis. logo kecil di cover hitam) → anggap gak berwarna.
  if (total / counted < 0.06 || weight[best] == 0) return null;

  final w = weight[best];
  return Color.fromARGB(255, (sumR[best] / w).round(), (sumG[best] / w).round(), (sumB[best] / w).round());
}

/// Dari beberapa warna jadi (mis. warna album demo), ambil yang paling hidup.
Color? vibrantFromColors(List<Color> colors) {
  Color? best;
  var score = 0.0;
  for (final c in colors) {
    final hsv = HSVColor.fromColor(c);
    final s = hsv.saturation * hsv.value;
    if (hsv.saturation >= 0.2 && s > score) {
      score = s;
      best = c;
    }
  }
  return best;
}

/// Warna aksen Nova ikut cover lagu yang lagi diputar (bisa dimatiin di pengaturan).
class CoverTintService extends ChangeNotifier {
  CoverTintService(this._audio);
  final PlayerService _audio;

  bool enabled = true;
  final _cache = <int, Color?>{};
  int _req = 0;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    enabled = p.getBool('accentFromCover') ?? true;
    _audio.current.addListener(_update);
    // Foto lagu diganti → warna aksen ikut dihitung ulang.
    Artwork.version.addListener(() {
      _cache.clear();
      _update();
    });
    await _update();
  }

  Future<void> setEnabled(bool v) async {
    enabled = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool('accentFromCover', v);
    await _update();
  }

  Future<void> _update() async {
    final req = ++_req;
    final song = _audio.current.value;
    if (!enabled || song == null) {
      setAccentTint(null);
      return;
    }
    final c = await _colorOf(song);
    // Lagu udah ganti lagi selagi nunggu → buang hasil lama.
    if (req != _req) return;
    setAccentTint(c);
  }

  Future<Color?> _colorOf(Song song) async {
    if (_cache.containsKey(song.id)) return _cache[song.id];
    Color? c;
    try {
      if (kDemo) {
        final a = demoAlbumOfSong(song.id);
        c = a == null ? null : vibrantFromColors([a.ink, a.base]);
      } else {
        final bytes = await Artwork.of(song.id, 160);
        if (bytes != null) c = await _fromImage(bytes);
      }
    } catch (_) {
      c = null;
    }
    return _cache[song.id] = c;
  }

  static Future<Color?> _fromImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 32, targetHeight: 32);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    frame.image.dispose();
    codec.dispose();
    return data == null ? null : vibrantFromRgba(data.buffer.asUint8List());
  }
}
