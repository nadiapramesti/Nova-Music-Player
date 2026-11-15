import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../demo/demo.dart';
import '../models.dart';

class LyricLine {
  const LyricLine(this.time, this.text);

  /// null = lirik biasa (gak sinkron).
  final Duration? time;
  final String text;
}

class Lyrics {
  const Lyrics(this.lines, {required this.source});
  final List<LyricLine> lines;

  /// "file .lrc" / "tertanam di lagu" / "demo"
  final String source;

  bool get synced => lines.isNotEmpty && lines.first.time != null;

  /// Indeks baris yang lagi dinyanyiin pada [pos]; -1 kalau belum mulai.
  int indexAt(Duration pos) {
    if (!synced) return -1;
    var lo = 0, hi = lines.length - 1, ans = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lines[mid].time! <= pos) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }
}

final _stamp = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
final _offsetTag = RegExp(r'^\[offset:\s*([+-]?\d+)\s*\]$', caseSensitive: false);
final _metaTag = RegExp(r'^\[[a-zA-Z]+:.*\]$');

/// Parse teks LRC. Ngerti banyak timestamp per baris, [offset:], dan baris metadata.
/// Teks tanpa timestamp sama sekali = lirik biasa (gak sinkron).
Lyrics? parseLrc(String raw, {String source = 'file .lrc'}) {
  final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').replaceFirst('﻿', '');
  var offsetMs = 0;
  final timed = <LyricLine>[];
  final plain = <String>[];

  for (final line in text.split('\n')) {
    final t = line.trim();
    if (t.isEmpty) {
      plain.add('');
      continue;
    }
    final off = _offsetTag.firstMatch(t);
    if (off != null) {
      offsetMs = int.tryParse(off.group(1)!) ?? 0;
      continue;
    }
    final stamps = _stamp.allMatches(t).toList();
    if (stamps.isEmpty) {
      if (!_metaTag.hasMatch(t)) plain.add(t);
      continue;
    }
    final words = t.substring(stamps.last.end).trim();
    for (final m in stamps) {
      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      final frac = m.group(3);
      final ms = frac == null ? 0 : int.parse(frac.padRight(3, '0').substring(0, 3));
      timed.add(LyricLine(Duration(milliseconds: min * 60000 + sec * 1000 + ms), words));
    }
  }

  if (timed.isNotEmpty) {
    // Offset positif = lirik muncul lebih awal.
    final shifted = timed
        .map((l) {
          final ms = l.time!.inMilliseconds - offsetMs;
          return LyricLine(Duration(milliseconds: ms < 0 ? 0 : ms), l.text);
        })
        .toList()
      ..sort((a, b) => a.time!.compareTo(b.time!));
    return Lyrics(shifted, source: source);
  }

  // Rapikan baris kosong di awal/akhir & dobel.
  final cleaned = <String>[];
  for (final p in plain) {
    if (p.isEmpty && (cleaned.isEmpty || cleaned.last.isEmpty)) continue;
    cleaned.add(p);
  }
  while (cleaned.isNotEmpty && cleaned.last.isEmpty) {
    cleaned.removeLast();
  }
  if (cleaned.isEmpty) return null;
  return Lyrics(cleaned.map((e) => LyricLine(null, e)).toList(), source: source);
}

/// Cari lirik: file .lrc di samping lagu dulu, lalu lirik yang tertanam di file lagu.
class LyricsService {
  static const _ch = MethodChannel('nova/media');
  final _cache = <int, Future<Lyrics?>>{};

  Future<Lyrics?> of(Song song) => _cache.putIfAbsent(song.id, () => _load(song));

  /// Lupain cache (mis. setelah izin file dikasih).
  void clear() => _cache.clear();

  Future<Lyrics?> _load(Song song) async {
    if (kDemo) return _demo(song);
    final lrc = await _sidecar(song);
    if (lrc != null) return lrc;
    try {
      final raw = await _ch.invokeMethod<String>('lyrics', {'id': song.id});
      if (raw != null && raw.trim().isNotEmpty) return parseLrc(raw, source: 'tertanam di lagu');
    } catch (e) {
      debugPrint('lirik tertanam gagal: $e');
    }
    return null;
  }

  Future<Lyrics?> _sidecar(Song song) async {
    if (song.path.isEmpty) return null;
    final dot = song.path.lastIndexOf('.');
    final base = dot > song.path.lastIndexOf('/') ? song.path.substring(0, dot) : song.path;
    for (final ext in const ['.lrc', '.LRC', '.Lrc']) {
      try {
        final f = File('$base$ext');
        if (await f.exists()) {
          final raw = await f.readAsString().catchError((_) async => latin1.decode(await f.readAsBytes()));
          return parseLrc(raw);
        }
      } catch (_) {
        // Gak ada izin baca file non-media → lanjut ke lirik tertanam.
      }
    }
    return null;
  }

  /// Izin "akses semua file" (Android 11+) buat baca .lrc di samping lagu.
  Future<bool> hasFileAccess() async {
    if (!Platform.isAndroid) return true;
    return Permission.manageExternalStorage.isGranted;
  }

  Future<void> requestFileAccess() async {
    await Permission.manageExternalStorage.request();
    clear();
  }

  Lyrics _demo(Song song) {
    const words = [
      'Lampu kota pelan-pelan padam',
      'Aku masih di sini, di peron yang sama',
      'Kereta terakhir lewat tanpa suara',
      'Dan namamu tertinggal di kaca jendela',
      '',
      'Putar lagi, putar lagi',
      'Lagu yang cuma kita yang tau',
      'Putar lagi, putar lagi',
      'Sampai pagi lupa caranya datang',
      '',
      'Langit oranye jadi biru tua',
      'Semua sinyal hilang, cuma ada kita',
    ];
    final step = song.durationMs ~/ (words.length + 2);
    return Lyrics([
      for (var i = 0; i < words.length; i++) LyricLine(Duration(milliseconds: step * (i + 1)), words[i]),
    ], source: 'demo');
  }
}
