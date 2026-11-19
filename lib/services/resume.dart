import 'dart:convert';

import '../models.dart';

/// Posisi terakhir yang disimpan: antrean (urutan asli), lagu ke berapa,
/// detiknya, dan mode acak/ulang. Dipakai buat "lanjut dari terakhir".
class ResumeState {
  const ResumeState({
    required this.ids,
    required this.index,
    this.positionMs = 0,
    this.from,
    this.shuffle = false,
    this.loop = 'off',
  });

  final List<int> ids;
  final int index;
  final int positionMs;
  final String? from;
  final bool shuffle;

  /// 'off' | 'all' | 'one'
  final String loop;

  String encode() => jsonEncode({
        'ids': ids,
        'i': index,
        'pos': positionMs,
        if (from != null) 'from': from,
        'sh': shuffle,
        'loop': loop,
      });

  /// Rusak/kosong → null (Nova mulai bersih, gak crash).
  static ResumeState? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      final ids = (m['ids'] as List?)?.whereType<int>().toList() ?? const <int>[];
      final i = m['i'];
      if (ids.isEmpty || i is! int) return null;
      final loop = m['loop'];
      return ResumeState(
        ids: ids,
        index: i.clamp(0, ids.length - 1),
        positionMs: m['pos'] is int ? (m['pos'] as int).clamp(0, 1 << 31) : 0,
        from: m['from'] is String ? m['from'] as String : null,
        shuffle: m['sh'] == true,
        loop: loop == 'all' || loop == 'one' ? loop as String : 'off',
      );
    } catch (_) {
      return null;
    }
  }
}

/// Hasil pemulihan antrean dari [ResumeState] terhadap pustaka sekarang.
class RestoredQueue {
  const RestoredQueue(this.songs, this.index, this.position);
  final List<Song> songs;
  final int index;
  final Duration position;
}

/// Bangun ulang antrean. Lagu yang udah gak ada (dihapus/disembunyiin) dibuang.
/// Kalau lagu yang terakhir diputar ikut hilang, lanjut ke lagu sesudahnya dari awal.
RestoredQueue? restoreQueue(ResumeState state, Map<int, Song> byId) {
  final songs = <Song>[];
  int? index;
  var position = Duration.zero;
  for (var i = 0; i < state.ids.length; i++) {
    final s = byId[state.ids[i]];
    if (s == null) continue;
    if (i == state.index) {
      index = songs.length;
      // Detik di ujung lagu (< 3 dtk sebelum habis) = mulai lagi dari awal.
      final p = state.positionMs;
      position = p > 0 && p < s.durationMs - 3000 ? Duration(milliseconds: p) : Duration.zero;
    } else if (index == null && i > state.index) {
      index = songs.length; // lagu terakhir hilang → ambil yang berikutnya
    }
    songs.add(s);
  }
  if (songs.isEmpty) return null;
  return RestoredQueue(songs, index ?? 0, position);
}
