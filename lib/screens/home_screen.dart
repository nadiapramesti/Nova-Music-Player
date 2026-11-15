import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models.dart';
import '../services/services.dart';
import '../theme.dart';
import '../widgets/art.dart';
import '../widgets/controls.dart';
import '../widgets/message_view.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/song_row.dart';
import 'now_playing_screen.dart';

enum SortMode { terbaru, terlama, az }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SortMode _sort = SortMode.terbaru;

  static const _labels = {
    SortMode.terbaru: 'Terbaru',
    SortMode.terlama: 'Terlama',
    SortMode.az: 'A–Z',
  };

  List<Song> _sorted(List<Song> src) {
    final list = [...src]; // dari service sudah urut terbaru
    switch (_sort) {
      case SortMode.terbaru:
        return list;
      case SortMode.terlama:
        return list.reversed.toList();
      case SortMode.az:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) {
        switch (library.status) {
          case LibraryStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case LibraryStatus.needPermission:
            return MessageView(
              icon: Icons.lock_outline_rounded,
              title: 'Butuh izin akses musik',
              body: 'Nova cuma baca file lagu di HP lu. Gak ada yang dikirim ke internet.',
              actions: [
                WideButton(label: 'Izinkan akses musik', icon: Icons.music_note_rounded, onTap: library.load),
                WideButton(
                    label: 'Buka pengaturan',
                    icon: Icons.settings_rounded,
                    primary: false,
                    onTap: openAppSettings),
              ],
            );
          case LibraryStatus.error:
            return MessageView(
              icon: Icons.error_outline_rounded,
              title: 'Gagal baca lagu',
              body: library.errorMessage ?? 'Coba lagi ya.',
              actions: [WideButton(label: 'Coba lagi', icon: Icons.refresh_rounded, onTap: library.load)],
            );
          case LibraryStatus.ready:
            if (library.songs.isEmpty) {
              return MessageView(
                icon: Icons.library_music_outlined,
                title: 'Belum ada lagu',
                body: 'Taruh file MP3 / M4A / FLAC di HP lu, terus pindai ulang.',
                actions: [WideButton(label: 'Pindai ulang', icon: Icons.refresh_rounded, onTap: library.load)],
              );
            }
            return _ready(context);
        }
      },
    );
  }

  Widget _ready(BuildContext context) {
    final songs = library.songs;
    final sorted = _sorted(songs);
    final top = MediaQuery.of(context).padding.top;
    final from = 'Daftar putar · ${_labels[_sort]}';

    return Stack(
      children: [
        const Glow(top: -120, right: -140, size: 380),
        Glow(top: 430, left: -160, size: 360, color: Nv.glowSoft),
        RefreshIndicator(
          onRefresh: () => library.load(ask: false),
          color: Nv.accent,
          backgroundColor: Nv.coverBig,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, top + 14, 20, 0),
                  child: Row(
                    children: [
                      const NovaMark(size: 32),
                      const SizedBox(width: 6),
                      Text('nova', style: disp(26, spacing: -1)),
                      const Spacer(),
                      _ScanButton(onTap: () => library.load(ask: false)),
                      const SizedBox(width: 8),
                      GlassCircleButton(
                        icon: Icons.tune_rounded,
                        label: 'Pengaturan',
                        onTap: () => showSettingsSheet(context),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${songs.length} lagu.', style: disp(40, height: 0.98, spacing: -1.6)),
                      Text('Semuanya punya lu.',
                          style: disp(40, height: 0.98, spacing: -1.6, color: Nv.accent)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _ResumeCard(songs: songs)),
              SliverToBoxAdapter(child: SectionHeader('Daftar putar', trailing: '${songs.length}')),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Row(
                    children: [
                      for (final m in SortMode.values) ...[
                        Pill(label: _labels[m]!, selected: _sort == m, onTap: () => setState(() => _sort = m)),
                        const SizedBox(width: 6),
                      ],
                      Pill(
                        label: 'Acak',
                        icon: Icons.shuffle_rounded,
                        selected: false,
                        onTap: () => shuffleAndOpen(context, sorted, from: 'Daftar putar · Acak'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: sorted.length,
                itemBuilder: (context, i) => SongRow(
                  song: sorted[i],
                  number: i + 1,
                  onTap: () => playAndOpen(context, sorted, i, from: from),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 200)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 20,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 17, color: Nv.text),
                const SizedBox(width: 6),
                Text('Pindai ulang', style: disp(TS.body, w: 700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu "Lanjutkan": lagu terakhir yang diputar.
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.songs});
  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Song?>(
      valueListenable: audio.current,
      builder: (context, cur, _) {
        final song = cur ?? library.byId(stats.lastSongId) ?? songs.first;
        final isCurrent = cur?.id == song.id;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Glass(
            radius: 22,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Art(songId: song.id, size: 56, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isCurrent ? 'SEDANG DIPUTAR' : 'LANJUTKAN',
                          style: mono(TS.label, spacing: 1)),
                      const SizedBox(height: 3),
                      Text(song.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.lead, w: 700)),
                      const SizedBox(height: 6),
                      StreamBuilder<Duration>(
                        stream: audio.player.positionStream,
                        builder: (context, snap) {
                          final total = song.durationMs;
                          final pos = isCurrent ? (snap.data?.inMilliseconds ?? 0) : 0;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: total <= 0 ? 0 : (pos / total).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: Nv.track,
                              color: Nv.accent,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                RoundButton(
                  icon: isCurrent ? Icons.open_in_full_rounded : Icons.play_arrow_rounded,
                  label: isCurrent ? 'Buka pemutar' : 'Lanjutkan memutar',
                  fill: Nv.accent,
                  fg: Nv.onAccent,
                  onTap: () {
                    if (isCurrent) {
                      openNowPlaying(context);
                    } else {
                      final i = songs.indexWhere((s) => s.id == song.id);
                      playAndOpen(context, songs, i < 0 ? 0 : i, from: 'Daftar putar · Terbaru');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
