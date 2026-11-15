import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models.dart';
import '../services/services.dart';
import '../theme.dart';
import '../widgets/art.dart';
import '../services/sleep_timer.dart';
import '../widgets/controls.dart';
import '../widgets/deck.dart' show novaArtHero;
import '../widgets/lyrics_view.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/sleep_sheet.dart';

/// Putar dari daftar lalu langsung buka layar Sedang diputar.
void playAndOpen(BuildContext context, List<Song> songs, int index, {String? from}) {
  audio.playQueue(songs, index, from: from);
  openNowPlaying(context);
}

void shuffleAndOpen(BuildContext context, List<Song> songs, {String? from}) {
  audio.shuffleQueue(songs, from: from);
  openNowPlaying(context);
}

/// Layar pemutar lagi nampilin lirik (diingat selama app jalan).
final showLyrics = ValueNotifier<bool>(false);

void openNowPlaying(BuildContext context) {
  Navigator.of(context).push(PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => const NowPlayingScreen(),
    transitionsBuilder: (_, anim, __, child) {
      final c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(c),
        child: child,
      );
    },
  ));
}

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<Song?>(
        valueListenable: audio.current,
        builder: (context, song, _) {
          if (song == null) {
            return Center(child: Text('Belum ada lagu diputar', style: disp(TS.lead, w: 600)));
          }
          return Stack(
            children: [
              const Glow(top: 40, left: -60, size: 520),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      _TopBar(song: song),
                      const SizedBox(height: 16),
                      // Cover ⇄ lirik (tombol lirik di kiri atas).
                      Expanded(
                        child: ValueListenableBuilder<bool>(
                          valueListenable: showLyrics,
                          builder: (context, on, _) => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: on
                                ? LyricsView(key: const ValueKey('lyrics'), song: song)
                                : Center(key: const ValueKey('cover'), child: _Cover(song: song)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Panel(song: song),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassCircleButton(
          icon: Icons.keyboard_arrow_down_rounded,
          label: 'Tutup',
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
        ValueListenableBuilder<bool>(
          valueListenable: showLyrics,
          builder: (context, on, _) => on
              ? RoundButton(
                  icon: Icons.lyrics_rounded,
                  label: 'Tutup lirik',
                  size: 44,
                  iconSize: 20,
                  fill: Nv.accentSoft,
                  fg: Nv.accent,
                  border: Nv.accent,
                  onTap: () => showLyrics.value = false,
                )
              : GlassCircleButton(
                  icon: Icons.lyrics_outlined,
                  label: 'Lirik',
                  onTap: () => showLyrics.value = true,
                ),
        ),
        Expanded(
          child: StreamBuilder<int?>(
            stream: audio.player.currentIndexStream,
            builder: (context, _) => Column(
              children: [
                Text('TRACK ${twoDigits(audio.positionInQueue)} DARI ${audio.queue.length}',
                    style: mono(TS.label, spacing: 1.2)),
                const SizedBox(height: 2),
                ListenableBuilder(
                  listenable: Listenable.merge([audio.source, audio.sleep.listenable]),
                  builder: (context, _) {
                    final left = audio.sleep.left.value;
                    if (left != null || audio.sleep.endOfTrack.value) {
                      return Text(
                        left != null ? 'Berhenti dalam ${formatCountdown(left)}' : 'Berhenti di akhir lagu',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: disp(TS.body, w: 700, color: Nv.accent),
                      );
                    }
                    return Text(audio.source.value,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.body, w: 700));
                  },
                ),
              ],
            ),
          ),
        ),
        ListenableBuilder(
          listenable: audio.sleep.listenable,
          builder: (context, _) => audio.sleep.active
              ? RoundButton(
                  icon: Icons.bedtime_rounded,
                  label: 'Timer tidur aktif',
                  size: 44,
                  iconSize: 20,
                  fill: Nv.accentSoft,
                  fg: Nv.accent,
                  border: Nv.accent,
                  onTap: () => showSleepSheet(context),
                )
              : GlassCircleButton(
                  icon: Icons.bedtime_outlined,
                  label: 'Timer tidur',
                  onTap: () => showSleepSheet(context),
                ),
        ),
        const SizedBox(width: 8),
        GlassCircleButton(
          icon: Icons.queue_music_rounded,
          label: 'Lihat antrean',
          onTap: () => showQueueSheet(context),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Hero(
        tag: novaArtHero,
        // Material biar teks di dalam cover gak dapet garis bawah kuning pas terbang.
        flightShuttleBuilder: (_, __, dir, from, to) => Material(
          type: MaterialType.transparency,
          child: ((dir == HeroFlightDirection.push ? to : from).widget as Hero).child,
        ),
        child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 50, offset: Offset(0, 24))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Latar "nova" kalau file gak punya cover.
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Nv.coverBig,
                  gradient: const RadialGradient(
                    center: Alignment(0.44, -0.44),
                    radius: 0.8,
                    colors: [Color(0x8CAEB9FF), Color(0x00AEB9FF)],
                  ),
                  border: Border.all(color: Nv.glassLine),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('NOVA · ${twoDigits(audio.positionInQueue)}', style: mono(TS.label, spacing: 1.2)),
                      Text(song.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: disp(46, height: 0.95, spacing: -1.8)),
                    ],
                  ),
                ),
              ),
              Art(songId: song.id, big: true, radius: 0, fallback: const SizedBox.shrink()),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    final player = audio.player;
    return Glass(
      strong: true,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: disp(25, height: 1.05, spacing: -0.8)),
                    const SizedBox(height: 3),
                    Text('${song.artist} — ${song.album}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: disp(TS.body, w: 500, color: Nv.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ListenableBuilder(
                listenable: stats,
                builder: (context, _) {
                  final fav = stats.isFav(song.id);
                  return RoundButton(
                    icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: fav ? 'Hapus dari favorit' : 'Tambah ke favorit',
                    size: 46,
                    iconSize: 21,
                    fill: Nv.accentSoft,
                    fg: Nv.accent,
                    border: Nv.accent,
                    onTap: () => stats.toggleFav(song.id),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WaveSeek(song: song),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<bool>(
                stream: player.shuffleModeEnabledStream,
                builder: (context, snap) {
                  final on = snap.data ?? false;
                  return RoundButton(
                    icon: Icons.shuffle_rounded,
                    label: on ? 'Matikan acak' : 'Acak',
                    size: 46,
                    iconSize: 20,
                    fill: on ? Nv.accentSoft : Colors.transparent,
                    fg: on ? Nv.accent : Nv.text,
                    border: on ? Nv.accent : Nv.line,
                    onTap: audio.toggleShuffle,
                  );
                },
              ),
              RoundButton(
                icon: Icons.skip_previous_rounded,
                label: 'Lagu sebelumnya',
                size: 58,
                iconSize: 28,
                fill: Nv.chip,
                onTap: player.seekToPrevious,
              ),
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snap) {
                  final playing = snap.data?.playing ?? false;
                  return RoundButton(
                    icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    label: playing ? 'Jeda' : 'Putar',
                    size: 80,
                    iconSize: 38,
                    radius: 26,
                    fill: Nv.text,
                    fg: Nv.bg,
                    onTap: audio.togglePlay,
                  );
                },
              ),
              RoundButton(
                icon: Icons.skip_next_rounded,
                label: 'Lagu berikutnya',
                size: 58,
                iconSize: 28,
                fill: Nv.chip,
                onTap: player.seekToNext,
              ),
              StreamBuilder<LoopMode>(
                stream: player.loopModeStream,
                builder: (context, snap) {
                  final mode = snap.data ?? LoopMode.off;
                  final on = mode != LoopMode.off;
                  return RoundButton(
                    icon: mode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                    label: switch (mode) {
                      LoopMode.off => 'Ulangi semua',
                      LoopMode.all => 'Ulangi satu lagu',
                      LoopMode.one => 'Matikan ulangi',
                    },
                    size: 46,
                    iconSize: 20,
                    fill: on ? Nv.accentSoft : Colors.transparent,
                    fg: on ? Nv.accent : Nv.text,
                    border: on ? Nv.accent : Nv.line,
                    onTap: audio.cycleLoop,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<int?>(
            stream: player.currentIndexStream,
            builder: (context, _) {
              final next = audio.upNext;
              return Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Nv.rule))),
                child: Row(
                  children: [
                    Text('BERIKUTNYA', style: mono(TS.label, spacing: 1)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(next?.title ?? 'Akhir antrean',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.body, w: 700)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Seek bar model gelombang: bisa di-tap atau digeser.
class _WaveSeek extends StatefulWidget {
  const _WaveSeek({required this.song});
  final Song song;

  @override
  State<_WaveSeek> createState() => _WaveSeekState();
}

class _WaveSeekState extends State<_WaveSeek> {
  static const _bars = 44;
  double? _drag;

  List<double> _heights() {
    final r = Random(widget.song.id);
    return List.generate(_bars, (i) {
      final wave = (sin(i * 0.45) * 0.35 + 0.55);
      return (0.25 + wave * 0.55 + r.nextDouble() * 0.2).clamp(0.2, 1.0);
    });
  }

  void _seekTo(double f, Duration total) {
    audio.player.seek(Duration(milliseconds: (total.inMilliseconds * f).round()));
  }

  @override
  Widget build(BuildContext context) {
    final heights = _heights();
    return StreamBuilder<Duration?>(
      stream: audio.player.durationStream,
      builder: (context, durSnap) {
        final total = durSnap.data ?? widget.song.duration;
        return StreamBuilder<Duration>(
          stream: audio.player.positionStream,
          builder: (context, posSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final live = total.inMilliseconds <= 0
                ? 0.0
                : (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
            final f = _drag ?? live;
            final shown = Duration(milliseconds: (total.inMilliseconds * f).round());
            return Column(
              children: [
                LayoutBuilder(builder: (context, c) {
                  double frac(Offset o) => (o.dx / c.maxWidth).clamp(0.0, 1.0);
                  return Semantics(
                    slider: true,
                    label: 'Posisi lagu',
                    value: fmt(shown),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _seekTo(frac(d.localPosition), total),
                      onHorizontalDragStart: (d) => setState(() => _drag = frac(d.localPosition)),
                      onHorizontalDragUpdate: (d) => setState(() => _drag = frac(d.localPosition)),
                      onHorizontalDragEnd: (_) {
                        if (_drag != null) _seekTo(_drag!, total);
                        setState(() => _drag = null);
                      },
                      child: SizedBox(
                        height: 36,
                        child: Row(
                          children: [
                            for (var i = 0; i < _bars; i++) ...[
                              if (i > 0) const SizedBox(width: 3),
                              Expanded(
                                child: Center(
                                  child: Container(
                                    height: 24 * heights[i],
                                    decoration: BoxDecoration(
                                      color: (i + 0.5) / _bars <= f ? Nv.accent : Nv.track,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(fmt(shown), style: mono(TS.mono, color: Nv.accent)),
                    Text('−${fmt(total - shown)}', style: mono(TS.mono)),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
