import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Data Nova yang ikut dicadangkan. Kunci lain (mis. posisi lagu terakhir) gak ikut.
const backupKeys = <String>{
  'fav', // favorit
  'counts', // jumlah putar
  'lastPlayed',
  'recent',
  'last',
  'playlists',
  'songEdits', // info lagu yang diubah
  'hiddenFolders',
  'homeSort',
  'accentFromCover',
  'fadeSeconds',
  'islandAutoHide',
  'islandInApp',
  'islandOutside',
  'eq',
};

const _format = 'nova-backup';

/// Bikin isi file cadangan. Nilai yang tipenya aneh dilewatin.
String buildBackup(Map<String, Object?> values, {DateTime? now}) {
  final data = <String, Object>{};
  for (final k in backupKeys) {
    final v = values[k];
    if (v is String || v is int || v is bool || v is double) {
      data[k] = v!;
    } else if (v is List && v.every((e) => e is String)) {
      data[k] = List<String>.from(v);
    }
  }
  return const JsonEncoder.withIndent('  ').convert({
    'format': _format,
    'version': 1,
    'dibuat': (now ?? DateTime.now()).toIso8601String(),
    'data': data,
  });
}

/// Baca file cadangan. Bukan file Nova / rusak → null.
Map<String, Object>? parseBackup(String raw) {
  try {
    final m = jsonDecode(raw);
    if (m is! Map || m['format'] != _format || m['data'] is! Map) return null;
    final out = <String, Object>{};
    (m['data'] as Map).forEach((k, v) {
      if (k is! String || !backupKeys.contains(k)) return;
      if (v is String || v is int || v is bool || v is double) {
        out[k] = v as Object;
      } else if (v is List && v.every((e) => e is String)) {
        out[k] = List<String>.from(v);
      }
    });
    return out;
  } catch (_) {
    return null;
  }
}

/// Ringkasan isi cadangan buat ditampilin sebelum dipulihin.
({int favorites, int playlists, int edits}) summarizeBackup(Map<String, Object> data) {
  int count(String key) {
    final v = data[key];
    if (v is List) return v.length;
    if (v is String) {
      try {
        final d = jsonDecode(v);
        if (d is List) return d.length;
        if (d is Map) return d.length;
      } catch (_) {}
    }
    return 0;
  }

  return (favorites: count('fav'), playlists: count('playlists'), edits: count('songEdits'));
}

class BackupService {
  static const _ch = MethodChannel('nova/backup');

  /// Simpan cadangan. true = tersimpan, false = dibatalin.
  Future<bool> export() async {
    final p = await SharedPreferences.getInstance();
    final content = buildBackup({for (final k in backupKeys) k: p.get(k)});
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final name = 'nova-cadangan-${d.year}-${two(d.month)}-${two(d.day)}.json';
    final r = await _ch.invokeMethod<String>('save', {'name': name, 'content': content});
    return r == 'ok';
  }

  /// Pilih file cadangan. null = dibatalin; throw FormatException kalau bukan file Nova.
  Future<Map<String, Object>?> pick() async {
    final raw = await _ch.invokeMethod<String>('open');
    if (raw == null) return null;
    final data = parseBackup(raw);
    if (data == null) throw const FormatException('Bukan file cadangan Nova');
    return data;
  }

  /// Timpa data sekarang dengan isi cadangan, lalu buka ulang Nova.
  Future<void> restore(Map<String, Object> data) async {
    final p = await SharedPreferences.getInstance();
    for (final k in backupKeys) {
      await p.remove(k);
    }
    for (final e in data.entries) {
      final v = e.value;
      if (v is String) await p.setString(e.key, v);
      if (v is int) await p.setInt(e.key, v);
      if (v is bool) await p.setBool(e.key, v);
      if (v is double) await p.setDouble(e.key, v);
      if (v is List<String>) await p.setStringList(e.key, v);
    }
    await _ch.invokeMethod('restart');
  }
}
