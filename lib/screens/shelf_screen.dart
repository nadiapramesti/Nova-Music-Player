import 'package:flutter/material.dart';

import '../models.dart';
import '../services/services.dart';
import '../theme.dart';
import '../widgets/controls.dart';
import '../widgets/fast_scroll.dart';
import 'now_playing_screen.dart';
import 'song_list_screen.dart';
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

  final _filter = TextEditingController();
  final _listKey = GlobalKey();
  String _q = '';

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  void _setTab(ShelfTab t) {
    if (t == _tab) return;
    _filter.clear();
    setState(() {
      _tab = t;
      _q = '';
    });
  }

  static const _hints = {
    ShelfTab.album: 'Contoh: Manusia',
    ShelfTab.artis: 'Contoh: Tulus',
    ShelfTab.folder: 'Contoh: Download',
    ShelfTab.favorit: 'Contoh: Hati-Hati di Jalan',
  };

  /// Tinggi tetap satu punggung kaset (62) + jarak (8).
  static const _spineExtent = 70.0;
  static const _barH = 54.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([library, stats, audio.current, playlists]),
      builder: (context, _) {
        final q = _q.trim().toLowerCase();
        final allGroups = _groups();
        final groups = q.isEmpty
            ? allGroups.entries.toList()
            : allGroups.entries.where((e) => e.key.toLowerCase().contains(q)).toList();
        final allFavs = stats.favoriteSongs(library.songs);
        final favs = q.isEmpty
            ? allFavs
            : allFavs
                .where((s) => s.title.toLowerCase().contains(q) || s.artist.toLowerCase().contains(q))
                .toList();
        final curId = audio.current.value?.id;
        final countLabel = switch (_tab) {
          ShelfTab.favorit => '${allFavs.length} LAGU',
          ShelfTab.playlist => '${playlists.items.length} PLAYLIST',
          _ => '${allGroups.length} ${_labels[_tab]!.toUpperCase()}',
        };
        final isFav = _tab == ShelfTab.favorit;
        final count = isFav ? favs.length : groups.length;
        // Kotak saring cuma muncul kalau isinya udah lumayan banyak.
        final showFilter = _tab != ShelfTab.playlist && (isFav ? allFavs.length : allGroups.length) > 8;

        return Stack(
          children: [
            const Glow(top: -120, right: -140, size: 380),
            Glow(top: 420, left: -160, size: 360, color: Nv.glowSoft),
            Positioned.fill(
              top: mq.padding.top,
              child: FastScroller(
                itemCount: _tab == ShelfTab.playlist ? 0 : count,
                itemExtent: _spineExtent,
                listKey: _listKey,
                pinnedExtent: _barH,
                labelAt: isFav ? (i) => letterOf(favs[i].title) : (i) => letterOf(groups[i].key),
                minItems: 25,
                padding: EdgeInsets.only(top: _barH + 10, bottom: mq.padding.bottom + 130),
                child: CustomScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 6)),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: PinnedBarDelegate(
                        height: _barH,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              for (final t in ShelfTab.values) ...[
                                Pill(label: _labels[t]!, selected: _tab == t, onTap: () => _setTab(t)),
                                const SizedBox(width: 6),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (showFilter)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                          child: _FilterField(
                            controller: _filter,
                            hint: _hints[_tab] ?? 'Cari',
                            onChanged: (v) => setState(() => _q = v),
                          ),
                        ),
                      )
                    else
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    if (_tab == ShelfTab.playlist)
                      SliverToBoxAdapter(child: _PlaylistShelf(currentId: curId))
                    else if (isFav && allFavs.isEmpty)
                      SliverToBoxAdapter(child: _FavoritesShortcut.empty())
                    else if (count == 0)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                          child: Text('Gak ada yang cocok sama "${_q.trim()}".',
                              textAlign: TextAlign.center, style: disp(TS.body, w: 500, color: Nv.muted)),
                        ),
                      )
                    else
                      SliverFixedExtentList(
                        key: _listKey,
                        itemExtent: _spineExtent,
                        delegate: SliverChildBuilderDelegate(
                          childCount: count,
                          (context, i) {
                            if (isFav) {
                              final s = favs[i];
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                                child: _Spine(
                                  number: i + 1,
                                  title: s.title,
                                  subtitle: s.artist,
                                  trailing: fmt(s.duration),
                                  active: curId == s.id,
                                  onTap: () => playAndOpen(context, favs, i, from: 'Favorit'),
                                ),
                              );
                            }
                            final e = groups[i];
                            return Padding(
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
                            );
                          },
                        ),
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: mq.padding.bottom + 200)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Kotak saring kecil di Rak (album/artis/folder/favorit).
class _FilterField extends StatelessWidget {
  const _FilterField({required this.controller, required this.hint, required this.onChanged});
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 16,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, v, _) => TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          style: disp(TS.body, w: 600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: disp(TS.body, w: 500, color: Nv.muted),
            prefixIcon: Icon(Icons.filter_list_rounded, size: 20, color: Nv.text),
            suffixIcon: v.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus',
                    icon: Icon(Icons.close_rounded, size: 18, color: Nv.text),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
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
          child: WideButton(label: 'Playlist baru', icon: Icons.add_rounded, onTap: () => _create(context)),
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
            constraints: const BoxConstraints.tightFor(height: 62),
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

class _FavoritesShortcut {
  static Widget empty() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
        child: Text('Belum ada favorit. Tekan ikon hati di layar pemutar buat nambahin.',
            textAlign: TextAlign.center, style: disp(TS.body, w: 500, color: Nv.muted, height: 1.4)),
      );
}
