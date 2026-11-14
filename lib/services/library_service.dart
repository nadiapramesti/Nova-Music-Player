import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models.dart';

enum LibraryStatus { loading, needPermission, ready, error }

/// Baca lagu langsung dari MediaStore Android lewat channel sendiri
/// (lihat tool/MainActivity.kt.template). Tanpa internet.
class LibraryService extends ChangeNotifier {
  static const _ch = MethodChannel('nova/media');

  LibraryStatus status = LibraryStatus.loading;
  String? errorMessage;
  List<Song> songs = const [];

  Future<bool> _granted({required bool ask}) async {
    Future<PermissionStatus> check(Permission p) => ask ? p.request() : p.status;
    final ok = (await check(Permission.audio)).isGranted || (await check(Permission.storage)).isGranted;
    // Notifikasi buat kontrol lagu di luar app (Android 13+). Gak wajib.
    if (ok && ask) await Permission.notification.request();
    return ok;
  }

  Future<void> load({bool ask = true}) async {
    status = LibraryStatus.loading;
    notifyListeners();
    try {
      if (!await _granted(ask: ask)) {
        status = LibraryStatus.needPermission;
        notifyListeners();
        return;
      }
      final raw = await _ch.invokeListMethod<Map<Object?, Object?>>('songs') ?? const [];
      songs = raw
          .map((m) => Song.fromMap(m.map((k, v) => MapEntry(k.toString(), v))))
          // Buang suara < 30 detik (nada dering, voice note, dll).
          .where((s) => s.durationMs >= 30000)
          .toList();
      status = LibraryStatus.ready;
    } catch (e) {
      errorMessage = e.toString();
      status = LibraryStatus.error;
    }
    notifyListeners();
  }

  /// Sembunyikan app tanpa menutupnya (musik tetap jalan).
  Future<void> moveToBack() async {
    try {
      await _ch.invokeMethod<void>('moveToBack');
    } catch (_) {}
  }

  Song? byId(int? id) {
    if (id == null) return null;
    for (final s in songs) {
      if (s.id == id) return s;
    }
    return null;
  }

  Map<String, List<Song>> groupBy(String Function(Song) key) {
    final out = <String, List<Song>>{};
    for (final s in songs) {
      out.putIfAbsent(key(s), () => []).add(s);
    }
    final keys = out.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {for (final k in keys) k: out[k]!};
  }
}

/// Cover dari tag MP3, diambil dan dikecilkan di sisi Android, di-cache di memori.
class Artwork {
  static const _ch = MethodChannel('nova/media');
  static final _cache = <String, Future<Uint8List?>>{};

  static Future<Uint8List?> of(int songId, int size) {
    return _cache.putIfAbsent('$songId@$size', () async {
      try {
        return await _ch.invokeMethod<Uint8List>('artwork', {'id': songId, 'size': size});
      } catch (_) {
        return null;
      }
    });
  }
}
