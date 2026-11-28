import 'package:flutter/material.dart';

import '../demo/demo.dart';
import '../services/services.dart';
import '../theme.dart';
import 'controls.dart';
import 'eq_sheet.dart';
import 'song_actions.dart';
import '../models.dart';

void showSettingsSheet(BuildContext context) {
  showGlassSheet<void>(context, (sheet) {
    return ListenableBuilder(
      listenable: Listenable.merge([island, library, coverTint, audio.fadeSeconds, equalizer]),
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengaturan', style: disp(TS.h2, spacing: -0.6)),
          const _Label('Tampilan'),
          _Group(children: [
            _Toggle(
              title: 'Warna ikut cover',
              body: 'Aksen berubah ngikutin cover lagu.',
              value: coverTint.enabled,
              onChanged: coverTint.setEnabled,
            ),
            if (kDemo)
              _Toggle(
                title: 'Tema terang',
                body: 'Cuma ada di mode demo.',
                value: Nv.isLight,
                onChanged: (v) => setPalette(v ? Palette.light : Palette.dark),
              ),
          ]),
          const _Label('Pemutaran'),
          _Group(children: [
            _Choices(
              title: 'Transisi halus',
              body: 'Suara turun-naik pelan pas ganti lagu.',
              options: [for (final s in transitionChoices) s == 0 ? 'Mati' : '$s dtk'],
              selected: transitionChoices.indexOf(audio.fadeSeconds.value),
              onSelect: (i) => audio.setFadeSeconds(transitionChoices[i]),
            ),
            _NavRow(
              icon: Icons.equalizer_rounded,
              label: 'Equalizer',
              value: equalizer.settings.enabled
                  ? (equalizer.settings.preset == 'Custom' ? 'Atur sendiri' : equalizer.settings.preset)
                  : 'Mati',
              onTap: () => showEqSheet(context),
            ),
          ]),
          const _Label('Pustaka & cadangan'),
          _Group(children: [
            _NavRow(
              icon: Icons.folder_off_outlined,
              label: 'Folder disembunyikan',
              value: library.hiddenFolders.isEmpty ? 'Tidak ada' : '${library.hiddenFolders.length} folder',
              onTap: () => showHiddenFoldersSheet(context),
            ),
            _NavRow(icon: Icons.save_alt_rounded, label: 'Simpan cadangan', onTap: () => _exportBackup(context)),
            _NavRow(icon: Icons.restore_rounded, label: 'Pulihkan cadangan', onTap: () => _importBackup(context)),
          ]),
          const _Label('Pulau di notch'),
          _Group(children: [
            _Toggle(
              title: 'Di luar Nova',
              body: 'Muncul di area kamera, lalu ngumpet sendiri.',
              value: island.outside,
              onChanged: island.setOutside,
            ),
            _Toggle(
              title: 'Juga di dalam Nova',
              body: 'Biasanya gak perlu, udah ada pemutar mini.',
              value: island.inApp,
              onChanged: island.setInApp,
            ),
          ]),
        ],
      ),
    );
  });
}

/// Judul kecil tiap bagian (kapital mono), biar daftar pengaturan ringkas & rapi.
class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(text.toUpperCase(), style: mono(TS.label, spacing: 1.2)),
      );
}

/// Satu kartu berisi beberapa baris, dipisah garis tipis.
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Nv.chip,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Nv.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: Nv.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Baris yang buka layar lain: ikon, label, nilai sekarang, panah.
class _NavRow extends StatelessWidget {
  const _NavRow({required this.icon, required this.label, required this.onTap, this.value});
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Nv.text),
              const SizedBox(width: 12),
              Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.title, w: 600))),
              if (value != null) ...[
                Text(value!, style: disp(TS.caption, w: 500, color: Nv.muted)),
                const SizedBox(width: 4),
              ],
              Icon(Icons.chevron_right_rounded, size: 20, color: Nv.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris dengan beberapa pilihan (tombol sejajar).
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: disp(TS.title, w: 600)),
          const SizedBox(height: 2),
          Text(body, style: disp(TS.caption, w: 500, color: Nv.muted)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
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
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(color: on ? Nv.accent : Nv.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: SizedBox(
          height: 36,
          child: Center(child: Text(label, style: disp(TS.body, w: 700, color: on ? Nv.onAccent : Nv.text))),
        ),
      ),
    );
  }
}

/// Baris nyala/mati: judul + keterangan satu baris + saklar.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.title, required this.body, required this.value, required this.onChanged});

  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: disp(TS.title, w: 600)),
                    const SizedBox(height: 2),
                    Text(body, style: disp(TS.caption, w: 500, color: Nv.muted, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Nv.onAccent,
                  activeTrackColor: Nv.accent,
                  inactiveThumbColor: Nv.muted,
                  inactiveTrackColor: Nv.glass,
                ),
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
