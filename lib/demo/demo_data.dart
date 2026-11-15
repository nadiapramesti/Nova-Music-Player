import 'dart:ui';

import '../models.dart';

/// Album rekaan buat mode demo. Semua judul & artis FIKTIF (dikarang sendiri),
/// bukan lagu/artis asli, jadi aman dari masalah hak cipta.
class DemoAlbum {
  const DemoAlbum({
    required this.id,
    required this.title,
    required this.artist,
    required this.base,
    required this.ink,
    required this.pattern,
    required this.tracks,
  });

  final int id;
  final String title;
  final String artist;

  /// Warna dasar & warna gambar buat cover gradien (lihat demo_cover.dart).
  final Color base;
  final Color ink;
  final int pattern;

  /// (judul lagu, durasi dalam detik)
  final List<(String, int)> tracks;
}

const demoAlbums = <DemoAlbum>[
  DemoAlbum(
    id: 1,
    title: 'Kota Tanpa Sinyal',
    artist: 'Kirana Dusk',
    base: Color(0xFF2B2F6B),
    ink: Color(0xFFE38B6D),
    pattern: 0,
    tracks: [('Senja di Peron Lima', 228), ('Mode Pesawat', 201), ('Jalan Pulang Lewat Tol', 262), ('Sinyal Satu Bar', 187)],
  ),
  DemoAlbum(
    id: 2,
    title: 'Orbit Pelan',
    artist: 'Dermaga Lumen',
    base: Color(0xFF0F3B47),
    ink: Color(0xFF7FD1C7),
    pattern: 1,
    tracks: [('Orbit Pelan', 276), ('Gravitasi Kecil', 214), ('Bulan di Kaca Mobil', 243)],
  ),
  DemoAlbum(
    id: 3,
    title: 'Teh Jam Dua Pagi',
    artist: 'Halim & Kabut',
    base: Color(0xFF3A2440),
    ink: Color(0xFFC9A3E6),
    pattern: 2,
    tracks: [('Teh Jam Dua Pagi', 195), ('Lampu Dapur', 222), ('Selimut Abu-abu', 248), ('Hujan Belum Reda', 301)],
  ),
  DemoAlbum(
    id: 4,
    title: 'Peta Kertas',
    artist: 'Satelit Kertas',
    base: Color(0xFF1E2A3A),
    ink: Color(0xFFE9D8A6),
    pattern: 3,
    tracks: [('Peta Kertas', 233), ('Kompas Rusak', 179), ('Utara Itu Kamu', 256)],
  ),
  DemoAlbum(
    id: 5,
    title: 'Garis Pantai Utara',
    artist: 'Nadir Mekar',
    base: Color(0xFF16352A),
    ink: Color(0xFFA7D98B),
    pattern: 4,
    tracks: [('Ombak Nomor Tujuh', 268), ('Pasir di Saku', 204), ('Mercusuar', 239)],
  ),
  DemoAlbum(
    id: 6,
    title: 'Lampu Sein',
    artist: 'Orbit Kafe',
    base: Color(0xFF4A1F25),
    ink: Color(0xFFF2B5A0),
    pattern: 5,
    tracks: [('Lampu Sein Kanan', 212), ('Parkir Paralel', 191), ('Klakson Pelan-pelan', 226)],
  ),
];

/// ID lagu demo: album.id * 100 + nomor track (mulai 1), misal 301.
int demoSongId(int albumId, int track) => albumId * 100 + track;

DemoAlbum? demoAlbumOfSong(int songId) {
  final albumId = songId ~/ 100;
  for (final a in demoAlbums) {
    if (a.id == albumId) return a;
  }
  return null;
}

/// Daftar lagu demo, urut "terbaru" (seperti hasil MediaStore).
List<Song> demoSongs({DateTime? now}) {
  final t = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  final out = <Song>[];
  var age = 0;
  for (final a in demoAlbums) {
    for (var i = 0; i < a.tracks.length; i++) {
      final (title, secs) = a.tracks[i];
      final id = demoSongId(a.id, i + 1);
      out.add(Song(
        id: id,
        title: title,
        artist: a.artist,
        album: a.title,
        albumId: a.id,
        durationMs: secs * 1000,
        // Album pertama baru masuk minggu ini, sisanya makin lama.
        dateAdded: t - age * 86400,
        path: '/storage/emulated/0/Music/${a.artist}/${a.title}/${i + 1} $title.mp3',
        uri: 'demo://$id',
      ));
      age += a.id == 1 ? 1 : 6;
    }
  }
  return out;
}
