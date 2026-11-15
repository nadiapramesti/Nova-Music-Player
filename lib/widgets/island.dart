import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models.dart';
import '../screens/now_playing_screen.dart';
import '../services/services.dart';
import '../theme.dart';
import 'art.dart';

/// Pulau di notch: pil hitam di area kamera yang nunjukin lagu yang lagi diputar.
/// Tap = melebar jadi kontrol mini. Tap di luar = menyusut lagi.
/// Taruh sebagai `Positioned.fill(child: NowIsland())` paling atas di Stack.
class NowIsland extends StatefulWidget {
  const NowIsland({super.key});

  @override
  State<NowIsland> createState() => _NowIslandState();
}

class _NowIslandState extends State<NowIsland> with SingleTickerProviderStateMixin {
  late final AnimationController _eq =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  StreamSubscription<bool>? _sub;

  /// Ukuran target (melebar / menyusut).
  bool _open = false;

  /// Isi lebar baru ditampilkan setelah animasi ukuran selesai, biar gak luber.
  bool _showFull = false;

  @override
  void initState() {
    super.initState();
    _sub = audio.player.playingStream.listen((playing) {
      if (playing) {
        _eq.repeat();
      } else {
        _eq.stop();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _eq.dispose();
    super.dispose();
  }

  /// Lagu yang pulaunya disembunyikan (geser ke atas). Muncul lagi pas ganti lagu.
  int? _hiddenFor;

  void _toggle(bool open) => setState(() => _open = open);

  void _hide(Song song) => setState(() {
        _open = false;
        _showFull = false;
        _hiddenFor = song.id;
      });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final top = mq.padding.top;
    // Status bar nyerap tap, jadi pil di dalam app duduk tepat di bawah status bar
    // (gak ketutup kamera, judul kebaca). Mode Aksesibilitas: pil native yang di notch.
    const collapsedH = 30.0;
    const expandedH = 188.0;
    final y = top + 4;

    return ListenableBuilder(
      listenable: Listenable.merge([audio.current, island]),
      builder: (context, _) {
        final song = audio.current.value;
        if (song == null || !island.inApp || island.nativeEverywhere || _hiddenFor == song.id) {
          return const SizedBox.shrink();
        }
        return Stack(
          children: [
            if (_open)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggle(false),
                  child: const ColoredBox(color: Color(0x73000000)),
                ),
              ),
            // Kapsul di lubang kamera; pas dibuka, kartunya turun ke bawah status bar
            // biar gak ketutup kamera.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              top: _open ? top + 8 : y,
              left: 0,
              right: 0,
              child: Center(
                child: Semantics(
                  button: !_open,
                  label: _open ? null : 'Kontrol lagu: ${song.title}',
                  child: GestureDetector(
                    onTap: _open ? null : () => _toggle(true),
                    // Geser ke atas = sembunyikan sampai lagu berikutnya.
                    onVerticalDragEnd: (d) {
                      if ((d.primaryVelocity ?? 0) < -250) _hide(song);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      onEnd: () {
                        if (mounted) setState(() => _showFull = _open);
                      },
                      width: _open ? mq.size.width - 20 : 200,
                      height: _open ? expandedH : collapsedH,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(_open ? 36 : 15),
                        border: Border.all(color: _open ? Nv.glassLine : const Color(0x14FFFFFF)),
                        boxShadow: _open
                            ? const [BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 16))]
                            : const [],
                      ),
                      child: _content(song),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _content(Song song) {
    if (_open) {
      if (!_showFull) return const SizedBox.shrink();
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 180),
        builder: (context, v, child) => Opacity(opacity: v, child: child),
        child: _Expanded(
          song: song,
          eq: _eq,
          onOpenPlayer: () {
            _toggle(false);
            openNowPlaying(context);
          },
        ),
      );
    }
    if (_showFull) return const SizedBox.shrink(); // lagi menyusut
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 11, 0),
      child: Row(
        children: [
          ClipOval(child: Art(songId: song.id, size: 22, radius: 0)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(song.title,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(12, w: 700)),
          ),
          const SizedBox(width: 8),
          _EqBars(controller: _eq, height: 12),
        ],
      ),
    );
  }
}

class _Expanded extends StatelessWidget {
  const _Expanded({required this.song, required this.eq, required this.onOpenPlayer});

  final Song song;
  final AnimationController eq;
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    final player = audio.player;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onOpenPlayer,
            child: Row(
              children: [
                Art(songId: song.id, size: 52, radius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(16, w: 800)),
                      const SizedBox(height: 2),
                      Text(song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: disp(12.5, w: 500, color: Nv.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _EqBars(controller: eq, height: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snap) {
              final pos = snap.data ?? Duration.zero;
              final total = player.duration ?? song.duration;
              final f = total.inMilliseconds <= 0
                  ? 0.0
                  : (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
              return Row(
                children: [
                  Text(fmt(pos), style: mono(11, color: Nv.accent)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: f,
                        minHeight: 4,
                        backgroundColor: Nv.track,
                        color: Nv.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(fmt(total), style: mono(11)),
                ],
              );
            },
          ),
          const Spacer(),
          Row(
            children: [
              _IslandButton(icon: Icons.skip_previous_rounded, label: 'Lagu sebelumnya', onTap: player.seekToPrevious),
              const SizedBox(width: 8),
              Expanded(
                child: StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snap) {
                    final playing = snap.data?.playing ?? false;
                    return _IslandButton(
                      icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      label: playing ? 'Jeda' : 'Putar',
                      onTap: audio.togglePlay,
                      primary: true,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              _IslandButton(icon: Icons.skip_next_rounded, label: 'Lagu berikutnya', onTap: player.seekToNext),
              const SizedBox(width: 8),
              _IslandButton(icon: Icons.open_in_full_rounded, label: 'Buka pemutar', onTap: onOpenPlayer),
            ],
          ),
        ],
      ),
    );
  }
}

class _IslandButton extends StatelessWidget {
  const _IslandButton({required this.icon, required this.label, required this.onTap, this.primary = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: primary ? Nv.accent : const Color(0x1AFFFFFF),
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: SizedBox(
            width: primary ? null : 52,
            height: 48,
            child: Icon(icon, size: primary ? 28 : 24, color: primary ? Nv.onAccent : Nv.text),
          ),
        ),
      ),
    );
  }
}

/// Tiga batang equalizer yang goyang pas lagu jalan.
class _EqBars extends StatelessWidget {
  const _EqBars({required this.controller, required this.height});
  final AnimationController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * 2 * pi;
        final moving = controller.isAnimating;
        return SizedBox(
          height: height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: height / 7),
                Container(
                  width: height / 5,
                  height: moving ? height * (0.3 + 0.7 * (0.5 + 0.5 * sin(t + i * 1.9)).abs()) : height * 0.3,
                  decoration: BoxDecoration(
                    color: Nv.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
