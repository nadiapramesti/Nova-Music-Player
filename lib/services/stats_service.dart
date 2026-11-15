import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../demo/demo.dart';
import '../demo/demo_data.dart';
import '../models.dart';

/// Favorit, jumlah putar, terakhir diputar, riwayat pencarian. Semua disimpan lokal.
class StatsService extends ChangeNotifier {
  SharedPreferences? _p;

  final Set<int> favorites = {};
  final Map<int, int> counts = {};
  final Map<int, int> lastPlayed = {};
  List<String> recent = [];
  int? lastSongId;

  Future<void> init() async {
    if (kDemo) {
      _seedDemo();
      return;
    }
    final p = await SharedPreferences.getInstance();
    _p = p;
    favorites.addAll((p.getStringList('fav') ?? const []).map(int.tryParse).whereType<int>());
    _readMap(p.getString('counts'), counts);
    _readMap(p.getString('lastPlayed'), lastPlayed);
    recent = p.getStringList('recent') ?? [];
    lastSongId = p.getInt('last');
  }

  void _readMap(String? raw, Map<int, int> into) {
    if (raw == null) return;
    try {
      (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null && v is int) into[id] = v;
      });
    } catch (_) {}
  }

  String _writeMap(Map<int, int> m) => jsonEncode(m.map((k, v) => MapEntry('$k', v)));

  /// Mode demo: favorit, jumlah putar, dan riwayat contoh. [_p] tetap null,
  /// jadi gak ada yang ditulis ke penyimpanan HP.
  void _seedDemo() {
    final songs = demoSongs();
    final now = DateTime.now().millisecondsSinceEpoch;
    const day = 86400000;
    for (var i = 0; i < songs.length; i++) {
      final id = songs[i].id;
      if (i % 3 == 0) favorites.add(id);
      if (i < 12) {
        counts[id] = 40 - i * 3;
        lastPlayed[id] = now - i * day;
      } else {
        counts[id] = 1;
        lastPlayed[id] = now - (100 + i) * day;
      }
    }
    recent = ['Kirana Dusk', 'orbit', 'Teh Jam Dua Pagi'];
    lastSongId = songs[2].id;
  }

  bool isFav(int id) => favorites.contains(id);

  void toggleFav(int id) {
    if (!favorites.remove(id)) favorites.add(id);
    _p?.setStringList('fav', favorites.map((e) => '$e').toList());
    notifyListeners();
  }

  void played(int id) {
    counts[id] = (counts[id] ?? 0) + 1;
    lastPlayed[id] = DateTime.now().millisecondsSinceEpoch;
    lastSongId = id;
    _p?.setString('counts', _writeMap(counts));
    _p?.setString('lastPlayed', _writeMap(lastPlayed));
    _p?.setInt('last', id);
    notifyListeners();
  }

  void addRecent(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    recent = [t, ...recent.where((e) => e.toLowerCase() != t.toLowerCase())].take(6).toList();
    _p?.setStringList('recent', recent);
    notifyListeners();
  }

  // ---- Pintasan di layar Cari ----

  List<Song> mostPlayed(List<Song> all) {
    final list = all.where((s) => (counts[s.id] ?? 0) > 0).toList()
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    return list.take(25).toList();
  }

  List<Song> forgotten(List<Song> all) {
    final cutoff = DateTime.now().subtract(const Duration(days: 90)).millisecondsSinceEpoch;
    final list = all.where((s) => (lastPlayed[s.id] ?? 0) < cutoff).toList()
      ..sort((a, b) => (lastPlayed[a.id] ?? 0).compareTo(lastPlayed[b.id] ?? 0));
    return list.take(50).toList();
  }

  List<Song> newThisWeek(List<Song> all) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;
    return all.where((s) => s.dateAdded >= cutoff).toList();
  }

  List<Song> favoriteSongs(List<Song> all) => all.where((s) => favorites.contains(s.id)).toList();
}
