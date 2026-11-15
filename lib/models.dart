class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumId,
    required this.durationMs,
    required this.dateAdded,
    required this.path,
    required this.uri,
  });

  final int id;
  final String title;
  final String artist;
  final String album;
  final int albumId;
  final int durationMs;

  /// Detik sejak epoch (dari MediaStore).
  final int dateAdded;
  final String path;
  final String uri;

  Duration get duration => Duration(milliseconds: durationMs);

  Song copyWith({String? title, String? artist, String? album}) => Song(
        id: id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        albumId: albumId,
        durationMs: durationMs,
        dateAdded: dateAdded,
        path: path,
        uri: uri,
      );

  /// Path folder lengkap (buat bedain dua folder yang namanya sama).
  String get folderPath {
    final i = path.lastIndexOf('/');
    return i > 0 ? path.substring(0, i) : '/';
  }

  String get folder {
    final parts = path.split('/')..removeWhere((p) => p.isEmpty);
    return parts.length >= 2 ? parts[parts.length - 2] : 'Lainnya';
  }

  static String _clean(Object? v, String fallback) {
    final s = (v as String?)?.trim() ?? '';
    if (s.isEmpty || s == '<unknown>') return fallback;
    return s;
  }

  factory Song.fromMap(Map<String, dynamic> m) {
    final path = (m['path'] as String?) ?? '';
    final fileName = path.split('/').last;
    return Song(
      id: (m['id'] as num).toInt(),
      title: _clean(m['title'], fileName.isEmpty ? 'Tanpa judul' : fileName),
      artist: _clean(m['artist'], 'Artis tidak diketahui'),
      album: _clean(m['album'], 'Album tidak diketahui'),
      albumId: (m['albumId'] as num?)?.toInt() ?? -1,
      durationMs: (m['duration'] as num?)?.toInt() ?? 0,
      dateAdded: (m['dateAdded'] as num?)?.toInt() ?? 0,
      path: path,
      uri: (m['uri'] as String?) ?? Uri.file(path).toString(),
    );
  }
}

String fmt(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String twoDigits(int n) => n.toString().padLeft(2, '0');

/// Buang lagu yang ada di folder tersembunyi (subfolder-nya ikut).
List<Song> withoutHiddenFolders(List<Song> songs, Set<String> hidden) {
  if (hidden.isEmpty) return songs;
  bool isHidden(String folder) => hidden.any((h) => folder == h || folder.startsWith('$h/'));
  return songs.where((s) => !isHidden(s.folderPath)).toList();
}

/// Ringkasan folder: path, nama, jumlah lagu (urut nama).
List<(String path, String name, int count)> folderSummary(List<Song> songs) {
  final counts = <String, int>{};
  for (final s in songs) {
    counts[s.folderPath] = (counts[s.folderPath] ?? 0) + 1;
  }
  final out = counts.entries.map((e) {
    final name = e.key.split('/').where((p) => p.isNotEmpty).lastOrNull ?? '/';
    return (e.key, name, e.value);
  }).toList()
    ..sort((a, b) => a.$2.toLowerCase().compareTo(b.$2.toLowerCase()));
  return out;
}
