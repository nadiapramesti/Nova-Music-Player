import 'dart:convert';

import '../models.dart';

/// Info lagu yang diubah di Nova saja (file lagunya gak disentuh).
/// Kolom null = pakai info asli dari file.
class SongEdit {
  const SongEdit({this.title, this.artist, this.album});

  final String? title;
  final String? artist;
  final String? album;

  bool get isEmpty => title == null && artist == null && album == null;

  Map<String, String> toJson() => {
        if (title != null) 't': title!,
        if (artist != null) 'a': artist!,
        if (album != null) 'al': album!,
      };

  static SongEdit fromJson(Map<String, dynamic> m) {
    String? pick(String k) {
      final v = m[k];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    return SongEdit(title: pick('t'), artist: pick('a'), album: pick('al'));
  }

  @override
  bool operator ==(Object other) =>
      other is SongEdit && other.title == title && other.artist == artist && other.album == album;

  @override
  int get hashCode => Object.hash(title, artist, album);
}

/// Dari isian form → perubahan. Kosong atau sama dengan aslinya = gak diubah.
SongEdit cleanEdit(Song original, {required String title, required String artist, required String album}) {
  String? keep(String input, String orig) {
    final v = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (v.isEmpty || v == orig) return null;
    return v.length > 120 ? v.substring(0, 120) : v;
  }

  return SongEdit(
    title: keep(title, original.title),
    artist: keep(artist, original.artist),
    album: keep(album, original.album),
  );
}

String encodeEdits(Map<int, SongEdit> edits) => jsonEncode({
      for (final e in edits.entries)
        if (!e.value.isEmpty) '${e.key}': e.value.toJson(),
    });

/// Rusak/kosong → map kosong (gak bikin app crash).
Map<int, SongEdit> decodeEdits(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final m = jsonDecode(raw);
    if (m is! Map) return {};
    final out = <int, SongEdit>{};
    for (final e in m.entries) {
      final id = int.tryParse('${e.key}');
      if (id == null || e.value is! Map) continue;
      final edit = SongEdit.fromJson(Map<String, dynamic>.from(e.value as Map));
      if (!edit.isEmpty) out[id] = edit;
    }
    return out;
  } catch (_) {
    return {};
  }
}

List<Song> applyEdits(List<Song> songs, Map<int, SongEdit> edits) {
  if (edits.isEmpty) return songs;
  return [
    for (final s in songs)
      if (edits[s.id] case final e?) s.copyWith(title: e.title, artist: e.artist, album: e.album) else s,
  ];
}
