import 'package:flutter/material.dart';

import '../models.dart';
import '../services/services.dart';
import '../theme.dart';
import '../widgets/controls.dart';
import 'now_playing_screen.dart';
import 'song_list_screen.dart';
import 'spotify_import_screen.dart';
import '../widgets/song_actions.dart';

enum ShelfTab { album, artis, folder, playlist, favorit }

/// "Rak": koleksi dikelompokkan, ditampilkan kayak deretan punggung kaset kaca.
class ShelfScreen extends StatefulWidget {
  const ShelfScreen({super.key});

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  ShelfTab _tab = ShelfTab.album;

  static const _labels = {
    ShelfTab.album: 'Album',
    ShelfTab.artis: 'Artis',
    ShelfTab.folder: 'Folder',
    ShelfTab.playlist: 'Playlist',
    ShelfTab.favorit: 'Favorit',
  };

  Map<String, List<Song>> _groups() {
    switch (_tab) {
      case ShelfTab.album:
        return library.groupBy((s) => s.album);
      case ShelfTab.artis:
        return library.groupBy((s) => s.artist);
      case ShelfTab.folder:
        return library.groupBy((s) => s.folder);
      case ShelfTab.playlist:
      case ShelfTab.favorit:
        return const {};
    }
  }

  String _sub(List<Song> songs) {
    switch (_tab) {
      case ShelfTab.album:
        return songs.first.artist;
      case ShelfTab.artis:
        return '${songs.map((s) => s.album).toSet().length} album';
      case ShelfTab.folder:
        return songs.first.artist;
      case ShelfTab.playlist:
      case ShelfTab.favorit:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ListenableBuilder(
      listenable: Listenable.merge([library, stats, audio.current, playlists]),
      builder: (context, _) {
        final groups = _groups();
        final favs = stats.favoriteSongs(library.songs);
        final curId = audio.current.value?.id;
        final countLabel = switch (_tab) {
          ShelfTab.favorit => '${favs.length} LAGU',
          ShelfTab.playlist => '${playlists.items.length} PLAYLIST',
          _ => '${groups.length} ${_labels[_tab]!.toUpperCase()}',
        };

        return Stack(
          children: [
            const Glow(top: -120, right: -140, size: 380),
            Glow(top: 420, left: -160, size: 360, color: Nv.glowSoft),
            ListView(
              padding: EdgeInsets.fromLTRB(0, top + 14, 0, 200),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: Text('Rak', style: disp(40, spacing: -1.6))),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(countLabel, style: mono(TS.mono, w: 500)),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Row(
                    children: [
                      for (final t in ShelfTab.values) ...[
                        Pill(label: _labels[t]!, selected: _tab == t, onTap: () => setState(() => _tab = t)),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
                if (_tab == ShelfTab.favorit)
                  _FavoritesShortcut(songs: favs)
                else if (_tab == ShelfTab.playlist)
                  _PlaylistShelf(currentId: curId)
                else
                  for (final (i, e) in groups.entries.indexed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _Spine(
                        number: i + 1,
                        title: e.key,
                        subtitle: _sub(e.value),
                        trailing: '${e.value.length} LAGU',
                        active: curId != null && e.value.any((s) => s.id == curId),
                        onTap: () => SongListScreen.open(
                          context,
                          eyebrow: _labels[_tab]!,
                          title: e.key,
                          songs: e.value,
                        ),
                      ),
                    ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Tab Playlist: tombol bikin baru + daftar playlist.
class _PlaylistShelf extends StatelessWidget {
  const _PlaylistShelf({required this.currentId});
  final int? currentId;

  Future<void> _create(BuildContext context) async {
    final name = await askPlaylistName(context, title: 'Playlist baru');
    if (name == null || !context.mounted) return;
    final p = playlists.create(name);
    if (p != null) SongListScreen.openPlaylist(context, p.id);
  }

  @override
  Widget build(BuildContext context) {
    final items = playlists.items;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Expanded(child: WideButton(label: 'Playlist baru', icon: Icons.add_rounded, onTap: () => _create(context))),
              const SizedBox(width: 8),
              Expanded(
                child: WideButton(
                  label: 'Dari Spotify',
                  icon: Icons.playlist_add_rounded,
                  primary: false,
                  onTap: () => SpotifyImportScreen.open(context),
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
            child: Text(
              'Belum ada playlist. Bikin satu, atau tahan lama lagu mana aja lalu pilih "Tambah ke playlist".',
              textAlign: TextAlign.center,
              style: disp(TS.body, w: 500, color: Nv.muted, height: 1.4),
            ),
          ),
        for (final (i, p) in items.indexed)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: _Spine(
              number: i + 1,
              title: p.name,
              subtitle: _artists(p.id),
              trailing: '${p.songIds.length} LAGU',
              active: currentId != null && p.songIds.contains(currentId),
              onTap: () => SongListScreen.openPlaylist(context, p.id),
            ),
          ),
      ],
    );
  }

  String _artists(String id) {
    final names = playlists.songsOf(id, library.songs).map((s) => s.artist).toSet().take(3).toList();
    return names.isEmpty ? 'Masih kosong' : names.join(', ');
  }
}

class _Spine extends StatelessWidget {
  const _Spine({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.active,
    required this.onTap,
  });

  final int number;
  final String title;
  final String subtitle;
  final String trailing;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Nv.accent : Nv.text;
    return Glass(
      radius: 14,
      color: active ? Nv.accentSoft : (number.isEven ? Nv.coverAlt : Nv.cover),
      borderColor: active ? const Color(0x66AEB9FF) : null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text(twoDigits(number), style: mono(TS.label, color: fg))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: disp(TS.lead, spacing: -0.4, color: fg)),
                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: disp(TS.caption, w: 500, color: Nv.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(trailing, style: mono(TS.label, color: fg)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoritesShortcut extends StatelessWidget {
  const _FavoritesShortcut({required this.songs});
  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
        child: Text('Belum ada favorit. Tekan ikon hati di layar pemutar buat nambahin.',
            textAlign: TextAlign.center, style: disp(TS.body, w: 500, color: Nv.muted, height: 1.4)),
      );
    }
    return Column(
      children: [
        for (final (i, s) in songs.indexed)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: _Spine(
              number: i + 1,
              title: s.title,
              subtitle: s.artist,
              trailing: fmt(s.duration),
              active: audio.current.value?.id == s.id,
              onTap: () => playAndOpen(context, songs, i, from: 'Favorit'),
            ),
          ),
      ],
    );
  }
}
