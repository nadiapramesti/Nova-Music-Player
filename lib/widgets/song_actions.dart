import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../services/services.dart';
import '../theme.dart';
import 'art.dart';
import 'controls.dart';

/// Lembar kaca standar buat aksi-aksi kecil.
Future<T?> showGlassSheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        0,
        8,
        MediaQuery.of(context).padding.bottom + 8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Glass(
        strong: true,
        radius: 28,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: builder(context),
      ),
    ),
  );
}

/// Tahan lama di baris lagu: aksi buat lagu itu.
/// [playlistId] diisi kalau dibuka dari dalam playlist (muncul "Hapus dari playlist ini").
void showSongActions(BuildContext context, Song song, {String? playlistId}) {
  HapticFeedback.selectionClick();
  showGlassSheet<void>(context, (sheet) {
    return ListenableBuilder(
      listenable: stats,
      builder: (sheet, _) {
        final fav = stats.isFav(song.id);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Art(songId: song.id, size: 52, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(17)),
                      Text('${song.artist} · ${song.album}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(12.5, w: 500, color: Nv.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ActionTile(
              icon: Icons.playlist_add_rounded,
              label: 'Tambah ke playlist',
              onTap: () {
                Navigator.of(sheet).pop();
                showAddToPlaylist(context, song);
              },
            ),
            ActionTile(
              icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              label: fav ? 'Hapus dari favorit' : 'Tambah ke favorit',
              highlight: fav,
              onTap: () => stats.toggleFav(song.id),
            ),
            if (playlistId != null)
              ActionTile(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Hapus dari playlist ini',
                onTap: () {
                  playlists.remove(playlistId, song.id);
                  Navigator.of(sheet).pop();
                },
              ),
          ],
        );
      },
    );
  });
}

/// Pilih playlist (centang / hapus centang) + bikin playlist baru.
void showAddToPlaylist(BuildContext context, Song song) {
  showGlassSheet<void>(context, (sheet) {
    return ListenableBuilder(
      listenable: playlists,
      builder: (sheet, _) {
        final items = playlists.items;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TAMBAH KE PLAYLIST', style: mono(11, spacing: 1.2)),
            const SizedBox(height: 4),
            Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(22, spacing: -0.6)),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Belum ada playlist. Bikin satu dulu ya.',
                    style: disp(13.5, w: 500, color: Nv.muted)),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.4),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in items)
                      ActionTile(
                        icon: playlists.contains(p.id, song.id)
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        label: p.name,
                        trailing: '${p.songIds.length} LAGU',
                        highlight: playlists.contains(p.id, song.id),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          playlists.toggle(p.id, song.id);
                        },
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            WideButton(
              label: 'Playlist baru',
              icon: Icons.add_rounded,
              onTap: () async {
                final name = await askPlaylistName(sheet, title: 'Playlist baru');
                if (name == null) return;
                playlists.create(name, songIds: [song.id]);
              },
            ),
          ],
        );
      },
    );
  });
}

/// Form nama playlist. Balikin nama yang udah dirapikan, atau null kalau batal.
Future<String?> askPlaylistName(BuildContext context, {required String title, String initial = ''}) {
  final controller = TextEditingController(text: initial);
  return showGlassSheet<String>(context, (sheet) {
    void submit() {
      final t = controller.text.trim();
      if (t.isEmpty) return;
      Navigator.of(sheet).pop(t);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLAYLIST', style: mono(11, spacing: 1.2)),
        const SizedBox(height: 4),
        Text(title, style: disp(24, spacing: -0.6)),
        const SizedBox(height: 14),
        Text('NAMA PLAYLIST', style: mono(10.5, spacing: 1.2)),
        const SizedBox(height: 6),
        Glass(
          radius: 16,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            style: disp(15, w: 600),
            decoration: InputDecoration(
              hintText: 'Contoh: Lagu buat nyetir',
              hintStyle: disp(15, w: 500, color: Nv.muted),
              counterText: '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, v, _) => Opacity(
            opacity: v.text.trim().isEmpty ? 0.5 : 1,
            child: WideButton(label: 'Simpan', icon: Icons.check_rounded, onTap: submit),
          ),
        ),
      ],
    );
  });
}

/// Baris aksi berbentuk tombol (ikon + label), seragam di semua lembar.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(16);
    final fg = highlight ? Nv.accent : Nv.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: highlight ? Nv.accentSoft : Nv.chip,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 21, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(15, w: 700, color: fg)),
                ),
                if (trailing != null) Text(trailing!, style: mono(11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
