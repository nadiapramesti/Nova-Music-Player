import 'package:flutter/material.dart';

import '../demo/demo.dart';
import '../services/services.dart';
import '../theme.dart';
import 'controls.dart';
import 'eq_sheet.dart';
import 'song_actions.dart';
import '../models.dart';

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.sheet,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, MediaQuery.of(context).padding.bottom + 8),
      child: Glass(
        strong: true,
        radius: 28,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: SingleChildScrollView(child: ListenableBuilder(
          listenable: Listenable.merge([island, library, coverTint, audio.fadeSeconds]),
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PENGATURAN', style: mono(TS.label, spacing: 1.2)),
              const SizedBox(height: 4),
              Text('Tampilan', style: disp(TS.h2, spacing: -0.6)),
              const SizedBox(height: 14),
              _Toggle(
                title: 'Warna ikut cover',
                body: 'Warna aksen Nova berubah ngikutin cover lagu yang diputar. '
                    'Cover hitam-putih tetap pakai biru Nova.',
                value: coverTint.enabled,
                onChanged: coverTint.setEnabled,
              ),
              if (kDemo) ...[
                const SizedBox(height: 10),
                _Toggle(
                  title: 'Tema terang',
                  body: 'Buat perbandingan screenshot. Cuma ada di mode demo; versi biasa selalu gelap.',
                  value: Nv.isLight,
                  onChanged: (v) => setPalette(v ? Palette.light : Palette.dark),
                ),
              ],
              const SizedBox(height: 22),
              Text('Pemutaran', style: disp(TS.h2, spacing: -0.6)),
              const SizedBox(height: 14),
              _Choices(
                title: 'Transisi halus',
                body: 'Suara pelan turun di akhir lagu lalu pelan naik di lagu berikutnya, '
                    'biar pindah lagu gak kaget.',
                options: [for (final s in transitionChoices) s == 0 ? 'Mati' : '$s dtk'],
                selected: transitionChoices.indexOf(audio.fadeSeconds.value),
                onSelect: (i) => audio.setFadeSeconds(transitionChoices[i]),
              ),
              const SizedBox(height: 10),
              ListenableBuilder(
                listenable: equalizer,
                builder: (context, _) => ActionTile(
                  icon: Icons.equalizer_rounded,
                  label: 'Equalizer',
                  trailing: equalizer.settings.enabled
                      ? (equalizer.settings.preset == 'Custom' ? 'ATUR SENDIRI' : equalizer.settings.preset.toUpperCase())
                      : 'MATI',
                  onTap: () => showEqSheet(context),
                ),
              ),
              const SizedBox(height: 22),
              Text('Pustaka', style: disp(TS.h2, spacing: -0.6)),
              const SizedBox(height: 14),
              ActionTile(
                icon: Icons.folder_off_outlined,
                label: 'Folder yang disembunyikan',
                trailing: library.hiddenFolders.isEmpty ? 'TIDAK ADA' : '${library.hiddenFolders.length} FOLDER',
                onTap: () => showHiddenFoldersSheet(context),
              ),
              const SizedBox(height: 22),
              Text('Cadangan', style: disp(TS.h2, spacing: -0.6)),
              const SizedBox(height: 4),
              Text(
                'Playlist, favorit, info lagu yang diubah, dan pengaturan. '
                'Simpan dulu sebelum hapus-pasang Nova.',
                style: disp(TS.caption, w: 500, color: Nv.muted, height: 1.35),
              ),
              const SizedBox(height: 12),
              ActionTile(
                icon: Icons.save_alt_rounded,
                label: 'Simpan cadangan',
                onTap: () => _exportBackup(context),
              ),
              ActionTile(
                icon: Icons.restore_rounded,
                label: 'Pulihkan dari cadangan',
                onTap: () => _importBackup(context),
              ),
              const SizedBox(height: 22),
              Text('Pulau di notch', style: disp(TS.h2, spacing: -0.6)),
              const SizedBox(height: 14),
              _Toggle(
                title: 'Pulau di luar Nova',
                body: 'Pil lagu muncul di area kamera pas lu buka app lain, lalu ngumpet sendiri '
                    'jadi garis kecil. Tap = kartu lagu, tahan = buka Nova.',
                value: island.outside,
                onChanged: island.setOutside,
              ),
              const SizedBox(height: 10),
              _Toggle(
                title: 'Juga tampil di dalam Nova',
                body: 'Biasanya gak perlu, info lagunya udah ada di pemutar mini bawah.',
                value: island.inApp,
                onChanged: island.setInApp,
              ),
            ],
          ),
        )),
      ),
    ),
  );
}

/// Kartu pengaturan dengan beberapa pilihan (tombol sejajar).
class _Choices extends StatelessWidget {
  const _Choices({
    required this.title,
    required this.body,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final String body;
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(color: Nv.chip, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: disp(TS.title, w: 700)),
          const SizedBox(height: 3),
          Text(body, style: disp(TS.caption, w: 500, color: Nv.muted, height: 1.35)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _ChoiceButton(label: options[i], on: i == selected, onTap: () => onSelect(i))),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? Nv.accent : Nv.glass,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: on ? Nv.accent : Nv.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(label, style: disp(TS.body, w: 700, color: on ? Nv.onAccent : Nv.text)),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.title, required this.body, required this.value, required this.onChanged});

  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Nv.chip,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: disp(TS.title, w: 700)),
                    const SizedBox(height: 3),
                    Text(body, style: disp(TS.caption, w: 500, color: Nv.muted, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Nv.onAccent,
                activeTrackColor: Nv.accent,
                inactiveThumbColor: Nv.muted,
                inactiveTrackColor: Nv.chip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pilih folder yang lagunya gak mau ditampilin (rekaman WA, nada dering, dll).
void showHiddenFoldersSheet(BuildContext context) {
  showGlassSheet<void>(context, (sheet) {
    return ListenableBuilder(
      listenable: library,
      builder: (sheet, _) {
        final folders = folderSummary(library.allSongs);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PUSTAKA', style: mono(TS.label, spacing: 1.2)),
            const SizedBox(height: 4),
            Text('Sembunyikan folder', style: disp(TS.h2, spacing: -0.6)),
            const SizedBox(height: 6),
            Text('Lagu di folder yang dicentang gak muncul di Nova. File-nya tetap aman di HP.',
                style: disp(TS.body, w: 500, color: Nv.muted, height: 1.35)),
            const SizedBox(height: 14),
            if (folders.isEmpty)
              Text('Belum ada lagu yang kebaca.', style: disp(TS.body, w: 500, color: Nv.muted))
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.55),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final (path, name, count) in folders)
                      _FolderTile(
                        name: name,
                        path: path,
                        count: count,
                        hidden: library.hiddenFolders.contains(path),
                        onTap: () => library.toggleFolder(path),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  });
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.name,
    required this.path,
    required this.count,
    required this.hidden,
    required this.onTap,
  });

  final String name;
  final String path;
  final int count;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(16);
    final short = path.replaceFirst(RegExp(r'^/storage/emulated/0'), '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: hidden ? Nv.accentSoft : Nv.chip,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Icon(hidden ? Icons.visibility_off_rounded : Icons.folder_outlined,
                    size: 21, color: hidden ? Nv.accent : Nv.text),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: disp(TS.title, w: 700, color: hidden ? Nv.accent : Nv.text)),
                      Text(short.isEmpty ? '/' : short,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: mono(TS.label, w: 500)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(hidden ? 'DISEMBUNYIKAN' : '$count LAGU', style: mono(TS.label, color: hidden ? Nv.accent : null)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _backup = BackupService();

Future<void> _exportBackup(BuildContext context) async {
  try {
    final ok = await _backup.export();
    if (ok && context.mounted) showToast(context, 'Cadangan tersimpan');
  } catch (_) {
    if (context.mounted) showToast(context, 'Gagal nyimpen cadangan, coba pilih folder lain');
  }
}

Future<void> _importBackup(BuildContext context) async {
  Map<String, Object>? data;
  try {
    data = await _backup.pick();
  } on FormatException {
    if (context.mounted) showToast(context, 'File itu bukan cadangan Nova');
    return;
  } catch (_) {
    if (context.mounted) showToast(context, 'File gak bisa dibaca');
    return;
  }
  if (data == null || !context.mounted) return;
  final found = data;
  final sum = summarizeBackup(found);
  await showGlassSheet<void>(context, (sheet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CADANGAN', style: mono(TS.label, spacing: 1.2)),
        const SizedBox(height: 4),
        Text('Pulihkan data ini?', style: disp(TS.h2, spacing: -0.6)),
        const SizedBox(height: 6),
        Text(
          '${sum.favorites} favorit · ${sum.playlists} playlist · ${sum.edits} info lagu diubah. '
          'Data Nova yang sekarang bakal diganti, lalu Nova dibuka ulang (musik berhenti sebentar).',
          style: disp(TS.body, w: 500, color: Nv.muted, height: 1.4),
        ),
        const SizedBox(height: 18),
        WideButton(
          label: 'Batal',
          icon: Icons.close_rounded,
          primary: false,
          onTap: () => Navigator.of(sheet).pop(),
        ),
        const SizedBox(height: 8),
        WideButton(
          label: 'Pulihkan & buka ulang',
          icon: Icons.restore_rounded,
          onTap: () => _backup.restore(found),
        ),
      ],
    );
  });
}
