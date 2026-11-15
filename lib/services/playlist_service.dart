import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../demo/demo.dart';
import '../demo/demo_data.dart';
import '../models.dart';

class Playlist {
  Playlist({required this.id, required this.name, List<int>? songIds, int? createdAt})
      : songIds = songIds ?? [],
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  final String id;
  String name;
  final List<int> songIds;
  final int createdAt;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'songs': songIds, 'created': createdAt};

  static Playlist? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    if (id is! String || name is! String) return null;
    final songs = (raw['songs'] is List ? raw['songs'] as List : const [])
        .whereType<num>()
        .map((e) => e.toInt())
        .toList();
    final created = raw['created'];
    return Playlist(id: id, name: name, songIds: songs, createdAt: created is num ? created.toInt() : 0);
  }
}

/// Encode/decode daftar playlist (publik buat test).
String encodePlaylists(List<Playlist> items) => jsonEncode(items.map((p) => p.toJson()).toList());

List<Playlist> decodePlaylists(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final list = jsonDecode(raw);
    if (list is! List) return [];
    return list.map(Playlist.fromJson).whereType<Playlist>().toList();
  } catch (_) {
    return [];
  }
}

/// Nama playlist dirapikan: spasi di ujung dibuang, maks 40 huruf. Kosong = null.
String? cleanPlaylistName(String raw) {
  final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return null;
  return t.length > 40 ? t.substring(0, 40).trimRight() : t;
}

/// Playlist buatan sendiri, disimpan di HP.
class PlaylistService extends ChangeNotifier {
  SharedPreferences? _p;
  List<Playlist> items = [];
  int _seq = 0;

  Future<void> init() async {
    if (kDemo) {
      final songs = demoSongs();
      items = [
        Playlist(id: 'demo-1', name: 'Nyetir malam', songIds: songs.take(6).map((s) => s.id).toList()),
        Playlist(id: 'demo-2', name: 'Fokus kerja', songIds: songs.skip(8).take(5).map((s) => s.id).toList()),
      ];
      return;
    }
    final p = await SharedPreferences.getInstance();
    _p = p;
    items = decodePlaylists(p.getString('playlists'));
  }

  void _save() {
    _p?.setString('playlists', encodePlaylists(items));
    notifyListeners();
  }

  Playlist? byId(String id) {
    for (final p in items) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Bikin playlist baru (paling atas). Null kalau nama kosong.
  Playlist? create(String rawName, {List<int> songIds = const []}) {
    final name = cleanPlaylistName(rawName);
    if (name == null) return null;
    final p = Playlist(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
      name: name,
      songIds: songIds.toSet().toList(),
    );
    items = [p, ...items];
    _save();
    return p;
  }

  bool rename(String id, String rawName) {
    final p = byId(id);
    final name = cleanPlaylistName(rawName);
    if (p == null || name == null) return false;
    p.name = name;
    _save();
    return true;
  }

  void delete(String id) {
    items = items.where((p) => p.id != id).toList();
    _save();
  }

  bool contains(String id, int songId) => byId(id)?.songIds.contains(songId) ?? false;

  void add(String id, int songId) {
    final p = byId(id);
    if (p == null || p.songIds.contains(songId)) return;
    p.songIds.add(songId);
    _save();
  }

  void remove(String id, int songId) {
    final p = byId(id);
    if (p == null || !p.songIds.remove(songId)) return;
    _save();
  }

  void toggle(String id, int songId) => contains(id, songId) ? remove(id, songId) : add(id, songId);

  /// Lagu-lagu playlist sesuai urutan, lewati yang filenya udah gak ada.
  List<Song> songsOf(String id, List<Song> library) {
    final p = byId(id);
    if (p == null) return const [];
    final index = {for (final s in library) s.id: s};
    return p.songIds.map((sid) => index[sid]).whereType<Song>().toList();
  }
}
