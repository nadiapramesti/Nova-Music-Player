import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Pengganti MediaStore Android buat laptop: baca lagu dari folder musik,
/// ambil judul/artis/cover/lirik dari tag file-nya, simpan cache biar cepat.
class DesktopMedia {
  DesktopMedia._();

  static const audioExt = {'mp3', 'm4a', 'aac', 'flac', 'ogg', 'oga', 'opus', 'wav', 'wma', 'aiff', 'aif', 'ape'};

  /// Path pakai "/" di semua OS (Windows juga ngerti), biar logika folder sama kayak HP.
  static String norm(String p) => p.replaceAll('\\', '/');

  /// Id lagu tetap dari path: dua hash FNV-1a 32-bit digabung jadi 53-bit
  /// (aman jadi int di Dart, JSON, & web).
  static int idOf(String path) {
    final bytes = utf8.encode(norm(path).toLowerCase());
    int fnv(int seed) {
      var h = seed;
      for (final c in bytes) {
        h ^= c;
        h = (h * 0x01000193) & 0xFFFFFFFF;
      }
      return h;
    }

    return ((fnv(0x811c9dc5) & 0x1FFFFF) << 32) | fnv(0x050c5d1f);
  }

  // ---- Folder musik ----

  static Future<List<String>> folders() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getStringList('musicFolders');
    if (saved != null && saved.isNotEmpty) return saved;
    final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
    return [norm('$home/Music')];
  }

  static Future<void> setFolders(List<String> f) async =>
      (await SharedPreferences.getInstance()).setStringList('musicFolders', f.map(norm).toList());

  static Future<String?> pickFolder() async {
    final d = await getDirectoryPath(confirmButtonText: 'Pakai folder ini');
    return d == null ? null : norm(d);
  }

  // ---- Pindai ----

  static Future<File> _cacheFile() async => File('${(await getApplicationSupportDirectory()).path}/library-cache.json');

  /// Semua lagu di folder musik. File yang belum berubah diambil dari cache.
  static Future<List<Song>> scan() async {
    final cacheFile = await _cacheFile();
    Map<String, dynamic> cache = {};
    try {
      if (await cacheFile.exists()) cache = jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;
    } catch (_) {}
    final next = <String, dynamic>{};
    final out = <Song>[];
    for (final folder in await folders()) {
      final dir = Directory(folder);
      if (!await dir.exists()) continue;
      await for (final e in dir.list(recursive: true, followLinks: false).handleError((_) {})) {
        if (e is! File) continue;
        final path = norm(e.path);
        final dot = path.lastIndexOf('.');
        if (dot < 0 || !audioExt.contains(path.substring(dot + 1).toLowerCase())) continue;
        FileStat st;
        try {
          st = await e.stat();
        } catch (_) {
          continue;
        }
        final key = '${st.modified.millisecondsSinceEpoch}:${st.size}';
        var m = cache[path] is Map && (cache[path] as Map)['k'] == key ? Map<String, dynamic>.from(cache[path] as Map) : null;
        m ??= _read(e, path, st, key);
        next[path] = m;
        out.add(Song.fromMap(m));
      }
    }
    try {
      await cacheFile.parent.create(recursive: true);
      await cacheFile.writeAsString(jsonEncode(next));
    } catch (_) {}
    return out;
  }

  static Map<String, dynamic> _read(File f, String path, FileStat st, String key) {
    String? title, artist, album;
    var ms = 0;
    try {
      final md = readMetadata(f, getImage: false);
      title = md.title;
      artist = md.artist;
      album = md.album;
      ms = md.duration?.inMilliseconds ?? 0;
    } catch (_) {}
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return {
      'k': key,
      'id': idOf(path),
      'title': (title?.trim().isNotEmpty ?? false) ? title : (dot > 0 ? name.substring(0, dot) : name),
      'artist': artist,
      'album': album,
      'albumId': idOf('${album ?? ''}|${artist ?? ''}'),
      'duration': ms,
      'dateAdded': st.modified.millisecondsSinceEpoch ~/ 1000,
      'path': path,
      'uri': Uri.file(path, windows: Platform.isWindows).toString(),
    };
  }

  // ---- Cover & lirik ----

  static final Map<int, String> _paths = {};
  static void remember(List<Song> songs) {
    _paths
      ..clear()
      ..addEntries(songs.map((s) => MapEntry(s.id, s.path)));
  }

  static Future<Directory> coverDir() async {
    final d = Directory('${(await getApplicationSupportDirectory()).path}/covers');
    await d.create(recursive: true);
    return d;
  }

  static Future<List<int>> coverIds() async {
    final d = await coverDir();
    return [
      for (final f in d.listSync())
        if (int.tryParse(f.uri.pathSegments.last.split('.').first) case final id?) id,
    ];
  }

  static Future<Uint8List?> artwork(int id) async {
    final custom = File('${(await coverDir()).path}/$id.jpg');
    if (await custom.exists()) return custom.readAsBytes();
    final path = _paths[id];
    if (path == null) return null;
    try {
      final md = readMetadata(File(path), getImage: true);
      if (md.pictures.isEmpty) return null;
      return md.pictures.first.bytes;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> embeddedLyrics(int id) async {
    final path = _paths[id];
    if (path == null) return null;
    try {
      final l = readMetadata(File(path), getImage: false).lyrics;
      return l == null || l.trim().isEmpty ? null : l;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> pickCover(int id) async {
    final f = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'Gambar', extensions: ['jpg', 'jpeg', 'png', 'webp']),
    ]);
    if (f == null) return null;
    final dest = File('${(await coverDir()).path}/$id.jpg');
    await dest.writeAsBytes(await f.readAsBytes());
    return dest.path;
  }

  static Future<void> removeCover(int id) async {
    final f = File('${(await coverDir()).path}/$id.jpg');
    if (await f.exists()) await f.delete();
  }

  static Future<bool> deleteSongs(List<int> ids) async {
    var all = true;
    for (final id in ids) {
      final p = _paths[id];
      try {
        if (p != null) await File(p).delete();
        await removeCover(id);
      } catch (_) {
        all = false;
      }
    }
    return all;
  }

  // ---- Cadangan ----

  static Future<bool> saveBackup(String name, String content) async {
    final loc = await getSaveLocation(suggestedName: name, acceptedTypeGroups: const [
      XTypeGroup(label: 'Cadangan Nova', extensions: ['json']),
    ]);
    if (loc == null) return false;
    await File(loc.path).writeAsString(content);
    return true;
  }

  static Future<String?> openBackup() async {
    final f = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'Cadangan Nova', extensions: ['json']),
    ]);
    return f?.readAsString();
  }

  /// Buka ulang Nova (habis pulihin cadangan).
  static Future<void> restart() async {
    await Process.start(Platform.resolvedExecutable, const [], mode: ProcessStartMode.detached);
    exit(0);
  }
}
