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
