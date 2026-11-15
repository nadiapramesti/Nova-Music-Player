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
                      Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.lead)),
                      Text('${song.artist} · ${song.album}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.caption, w: 500, color: Nv.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ActionTile(
              icon: Icons.queue_play_next_rounded,
              label: 'Putar berikutnya',
              onTap: () {
                Navigator.of(sheet).pop();
                audio.playNext(song);
                showToast(context, 'Diputar setelah lagu ini');
              },
            ),
            ActionTile(
              icon: Icons.add_to_queue_rounded,
              label: 'Tambah ke antrean',
              onTap: () {
                Navigator.of(sheet).pop();
                audio.addToQueue(song);
                showToast(context, 'Masuk ke akhir antrean');
              },
            ),
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
            ActionTile(
              icon: Icons.edit_outlined,
              label: 'Ubah info lagu',
              trailing: library.edits.containsKey(song.id) ? 'DIUBAH' : null,
              onTap: () {
                Navigator.of(sheet).pop();
                showEditSong(context, song);
              },
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
            Text('TAMBAH KE PLAYLIST', style: mono(TS.label, spacing: 1.2)),
            const SizedBox(height: 4),
            Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.h2, spacing: -0.6)),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Belum ada playlist. Bikin satu dulu ya.',
                    style: disp(TS.body, w: 500, color: Nv.muted)),
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
        Text('PLAYLIST', style: mono(TS.label, spacing: 1.2)),
        const SizedBox(height: 4),
        Text(title, style: disp(TS.h2, spacing: -0.6)),
        const SizedBox(height: 14),
        Text('NAMA PLAYLIST', style: mono(TS.label, spacing: 1.2)),
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
            style: disp(TS.title, w: 600),
            decoration: InputDecoration(
              hintText: 'Contoh: Lagu buat nyetir',
              hintStyle: disp(TS.title, w: 500, color: Nv.muted),
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

/// Ubah judul/artis/album di Nova saja. File lagunya gak diubah.
void showEditSong(BuildContext context, Song song) {
  final original = library.originalOf(song.id) ?? song;
  final edit = library.edits[song.id];
  final title = TextEditingController(text: edit?.title ?? original.title);
  final artist = TextEditingController(text: edit?.artist ?? original.artist);
  final album = TextEditingController(text: edit?.album ?? original.album);
  var saving = false; // cegah tap dobel nutup layar di belakang lembar

  showGlassSheet<void>(context, (sheet) {
    Future<void> save(SongEdit next) async {
      if (saving) return;
      saving = true;
      final nav = Navigator.of(sheet);
      final updated = await library.editSong(song.id, next);
      if (updated != null) audio.refreshSong(updated);
      nav.pop();
      if (context.mounted) showToast(context, next.isEmpty ? 'Info lagu dikembalikan ke asli' : 'Info lagu disimpan');
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INFO LAGU', style: mono(TS.label, spacing: 1.2)),
          const SizedBox(height: 4),
          Text('Ubah info lagu', style: disp(TS.h2, spacing: -0.6)),
          const SizedBox(height: 4),
          Text(
            'Cuma berubah di Nova. File lagunya tetap seperti aslinya.',
            style: disp(TS.caption, w: 500, color: Nv.muted, height: 1.35),
          ),
          const SizedBox(height: 14),
          _EditField(label: 'JUDUL', controller: title, hint: 'Contoh: Senja di Kota', autofocus: true),
          _EditField(label: 'ARTIS', controller: artist, hint: 'Contoh: Nama penyanyi'),
          _EditField(label: 'ALBUM', controller: album, hint: 'Contoh: Nama album', last: true),
          if (edit != null) ...[
            const SizedBox(height: 4),
            WideButton(
              label: 'Kembalikan ke asli',
              icon: Icons.restart_alt_rounded,
              primary: false,
              onTap: () => save(const SongEdit()),
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 8),
          WideButton(
            label: 'Simpan',
            icon: Icons.check_rounded,
            onTap: () => save(cleanEdit(original, title: title.text, artist: artist.text, album: album.text)),
          ),
        ],
      ),
    );
  });
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.last = false,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: mono(TS.label, spacing: 1.2)),
          const SizedBox(height: 6),
          Glass(
            radius: 16,
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              maxLength: 120,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              textInputAction: last ? TextInputAction.done : TextInputAction.next,
              style: disp(TS.title, w: 600),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: disp(TS.title, w: 500, color: Nv.muted),
                counterText: '',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.title, w: 700, color: fg)),
                ),
                if (trailing != null) Text(trailing!, style: mono(TS.label)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Notifikasi singkat melayang di atas dek bawah.
void showToast(BuildContext context, String text) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, style: disp(TS.body, w: 700, color: Nv.bg)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Nv.text,
      duration: const Duration(milliseconds: 1800),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 150),
    ));
}
