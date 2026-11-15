import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../demo/demo.dart';
import '../demo/demo_data.dart';
import '../models.dart';
import 'song_edits.dart';

enum LibraryStatus { loading, needPermission, ready, error }

/// Baca lagu langsung dari MediaStore Android lewat channel sendiri
/// (lihat tool/MainActivity.kt.template). Tanpa internet.
class LibraryService extends ChangeNotifier {
  static const _ch = MethodChannel('nova/media');

  LibraryStatus status = LibraryStatus.loading;
  String? errorMessage;
  /// Lagu yang tampil (tanpa folder tersembunyi).
  List<Song> songs = const [];

  /// Semua lagu hasil pindai, termasuk yang foldernya disembunyikan.
  List<Song> allSongs = const [];

  /// Path folder yang disembunyikan.
  Set<String> hiddenFolders = {};
  SharedPreferences? _p;

  /// Hasil pindai asli (sebelum info diubah di Nova).
  List<Song> _scanned = const [];

  /// Info lagu yang diubah di Nova (per id lagu).
  Map<int, SongEdit> edits = {};

  Song? originalOf(int id) {
    for (final s in _scanned) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Simpan/hapus perubahan info satu lagu. Balikin lagu versi barunya.
  Future<Song?> editSong(int id, SongEdit edit) async {
    final next = Map.of(edits);
    if (edit.isEmpty) {
      next.remove(id);
    } else {
      next[id] = edit;
    }
    edits = next;
    allSongs = applyEdits(_scanned, edits);
    _applyHidden();
    notifyListeners();
    if (!kDemo) {
      _p ??= await SharedPreferences.getInstance();
      await _p!.setString('songEdits', encodeEdits(edits));
    }
    for (final s in allSongs) {
      if (s.id == id) return s;
    }
    return null;
  }

  void _applyHidden() => songs = withoutHiddenFolders(allSongs, hiddenFolders);

  Future<void> toggleFolder(String path) async {
    final next = Set.of(hiddenFolders);
    if (!next.remove(path)) next.add(path);
    hiddenFolders = next;
    _applyHidden();
    notifyListeners();
    if (!kDemo) {
      _p ??= await SharedPreferences.getInstance();
      await _p!.setStringList('hiddenFolders', hiddenFolders.toList());
    }
  }

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
    if (kDemo) {
      // Mode demo: lagu rekaan, tanpa izin & tanpa baca file di HP.
      _scanned = demoSongs();
      allSongs = applyEdits(_scanned, edits);
      _applyHidden();
      status = LibraryStatus.ready;
      notifyListeners();
      return;
    }
    try {
      if (!await _granted(ask: ask)) {
        status = LibraryStatus.needPermission;
        notifyListeners();
        return;
      }
      _p ??= await SharedPreferences.getInstance();
      hiddenFolders = (_p!.getStringList('hiddenFolders') ?? const []).toSet();
      edits = decodeEdits(_p!.getString('songEdits'));
      final raw = await _ch.invokeListMethod<Map<Object?, Object?>>('songs') ?? const [];
      _scanned = raw
          .map((m) => Song.fromMap(m.map((k, v) => MapEntry(k.toString(), v))))
          // Buang suara < 30 detik (nada dering, voice note, dll).
          .where((s) => s.durationMs >= 30000)
          .toList();
      allSongs = applyEdits(_scanned, edits);
      _applyHidden();
      status = LibraryStatus.ready;
    } catch (e) {
      errorMessage = e.toString();
      status = LibraryStatus.error;
    }
    notifyListeners();
  }

  /// Sembunyikan app tanpa menutupnya (musik tetap jalan).
  Future<void> moveToBack() async {
    if (kDemo) return;
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
    if (kDemo) return Future.value(null);
    return _cache.putIfAbsent('$songId@$size', () async {
      try {
        return await _ch.invokeMethod<Uint8List>('artwork', {'id': songId, 'size': size});
      } catch (_) {
        return null;
      }
    });
  }
}
