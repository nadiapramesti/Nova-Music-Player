import 'dart:async';
import 'dart:math';
import 'dart:ui';

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

  /// Pulau lagi ngumpet (sembunyi otomatis).
  bool _gone = false;
  Timer? _goneTimer;
  int? _lastSongId;
  bool? _lastPlaying;

  @override
  void initState() {
    super.initState();
    _sub = audio.player.playingStream.listen((playing) {
      if (playing) {
        _eq.repeat();
      } else {
        _eq.stop();
      }
      if (_lastPlaying != null && _lastPlaying != playing) _wake();
      _lastPlaying = playing;
    });
    audio.current.addListener(_onSong);
    _armGone();
  }

  void _onSong() {
    final id = audio.current.value?.id;
    if (id != _lastSongId) {
      _lastSongId = id;
      _wake();
    }
  }

  /// Munculin lagi lalu pasang timer ngumpet.
  void _wake() {
    if (!mounted) return;
    if (_gone) setState(() => _gone = false);
    _armGone();
  }

  void _armGone() {
    _goneTimer?.cancel();
    if (!island.autoHide || _open) return;
    _goneTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_open && island.autoHide) setState(() => _gone = true);
    });
  }

  @override
  void dispose() {
    audio.current.removeListener(_onSong);
    _goneTimer?.cancel();
    _autoClose?.cancel();
    _sub?.cancel();
    _eq.dispose();
    super.dispose();
  }

  /// Lagu yang pulaunya disembunyikan (geser ke atas). Muncul lagi pas ganti lagu.
  int? _hiddenFor;

  /// Kartu nyusut sendiri kalau 5 detik gak disentuh.
  Timer? _autoClose;

  void _armAutoClose() {
    _autoClose?.cancel();
    if (!_open) return;
    _autoClose = Timer(const Duration(seconds: 5), () {
      if (mounted && _open) _toggle(false);
    });
  }

  void _toggle(bool open) {
    setState(() => _open = open);
    _armAutoClose();
    _armGone();
  }

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
    const expandedH = 206.0;
    final y = top + 4;

    return ListenableBuilder(
      listenable: Listenable.merge([audio.current, island]),
      builder: (context, _) {
        final song = audio.current.value;
        if (song == null || !island.inApp || _hiddenFor == song.id) {
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
            // Lagi ngumpet: pegangan kaca kecil di bawah status bar, tap = muncul lagi.
            Positioned(
              top: top + 2,
              left: 0,
              right: 0,
              child: Center(
                child: IgnorePointer(
                  ignoring: !_gone,
                  child: AnimatedOpacity(
                    opacity: _gone ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Semantics(
                      button: true,
                      label: 'Munculin pulau lagu',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _wake,
                        child: SizedBox(
                          width: 76,
                          height: 26,
                          child: Center(
                            child: Glass(
                              radius: 5,
                              color: const Color(0x47FFFFFF),
                              borderColor: const Color(0x78FFFFFF),
                              child: const SizedBox(width: 52, height: 10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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
              // Sembunyi otomatis: naik + pudar ke balik status bar.
              child: IgnorePointer(
                ignoring: _gone,
                child: AnimatedSlide(
                  offset: _gone ? const Offset(0, -1.4) : Offset.zero,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _gone ? 0 : 1,
                    duration: const Duration(milliseconds: 220),
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
        child: Listener(
          // Disentuh = timer nyusut diulang.
          onPointerDown: (_) => _armAutoClose(),
          child: _Expanded(
          song: song,
          eq: _eq,
          onOpenPlayer: () {
            _toggle(false);
            openNowPlaying(context);
          },
        ),
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
                maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.caption, w: 700)),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // Latar: cover lagu di-blur, jadi warna kartu ikut lagu yang diputar.
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34, tileMode: TileMode.decal),
            child: Transform.scale(scale: 1.4, child: Art(songId: song.id, radius: 0)),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99000000), Color(0xE6000000)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            children: [
              // Baris atas: cover, status + judul + artis, equalizer.
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onOpenPlayer,
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Color(0x80000000), blurRadius: 16, offset: Offset(0, 6)),
                        ],
                      ),
                      child: Art(songId: song.id, size: 54, radius: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder<bool>(
                            stream: player.playingStream,
                            builder: (context, snap) => Text(
                              (snap.data ?? false) ? 'SEDANG DIPUTAR' : 'DIJEDA',
                              style: mono(TS.monoTiny, spacing: 1.4, color: const Color(0xFFAEB9FF)),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: disp(TS.lead, w: 800, color: Colors.white, spacing: -0.3)),
                          Text(song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: disp(TS.caption, w: 500, color: const Color(0xB3FFFFFF))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _EqBars(controller: eq, height: 22),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _MiniWave(song: song),
              const SizedBox(height: 12),
              // Kontrol simetris: favorit · sebelumnya · PLAY · berikutnya · buka pemutar.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ListenableBuilder(
                    listenable: stats,
                    builder: (context, _) {
                      final fav = stats.isFav(song.id);
                      return _IslandButton(
                        icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        label: fav ? 'Hapus dari favorit' : 'Tambah ke favorit',
                        onTap: () => stats.toggleFav(song.id),
                        tint: fav ? const Color(0xFFAEB9FF) : null,
                      );
                    },
                  ),
                  _IslandButton(
                    icon: Icons.skip_previous_rounded,
                    label: 'Lagu sebelumnya',
                    onTap: player.seekToPrevious,
                    size: 48,
                  ),
                  StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (context, snap) {
                      final playing = snap.data?.playing ?? false;
                      return _IslandButton(
                        icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        label: playing ? 'Jeda' : 'Putar',
                        onTap: audio.togglePlay,
                        primary: true,
                        size: 58,
                      );
                    },
                  ),
                  _IslandButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Lagu berikutnya',
                    onTap: player.seekToNext,
                    size: 48,
                  ),
                  _IslandButton(
                    icon: Icons.open_in_full_rounded,
                    label: 'Buka pemutar',
                    onTap: onOpenPlayer,
                    iconSize: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Seek bar gelombang mini di dalam kartu notch; bisa di-tap / digeser.
class _MiniWave extends StatefulWidget {
  const _MiniWave({required this.song});
  final Song song;

  @override
  State<_MiniWave> createState() => _MiniWaveState();
}

class _MiniWaveState extends State<_MiniWave> {
  static const _bars = 36;
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final r = Random(widget.song.id);
    final heights = List.generate(_bars, (i) => 0.3 + 0.7 * (0.5 + 0.5 * sin(i * 0.55)) * (0.6 + r.nextDouble() * 0.4));
    return StreamBuilder<Duration>(
      stream: audio.player.positionStream,
      builder: (context, snap) {
        final total = audio.player.duration ?? widget.song.duration;
        final pos = snap.data ?? Duration.zero;
        final live = total.inMilliseconds <= 0 ? 0.0 : (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
        final f = _drag ?? live;
        final shown = Duration(milliseconds: (total.inMilliseconds * f).round());
        return Row(
          children: [
            SizedBox(width: 40, child: Text(fmt(shown), style: mono(TS.label, color: const Color(0xFFAEB9FF)))),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                double frac(Offset o) => (o.dx / c.maxWidth).clamp(0.0, 1.0);
                void seek(double v) => audio.player.seek(Duration(milliseconds: (total.inMilliseconds * v).round()));
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => seek(frac(d.localPosition)),
                  onHorizontalDragUpdate: (d) => setState(() => _drag = frac(d.localPosition)),
                  onHorizontalDragEnd: (_) {
                    if (_drag != null) seek(_drag!);
                    setState(() => _drag = null);
                  },
                  child: SizedBox(
                    height: 22,
                    child: Row(
                      children: [
                        for (var i = 0; i < _bars; i++) ...[
                          if (i > 0) const SizedBox(width: 2),
                          Expanded(
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 18 * heights[i],
                                decoration: BoxDecoration(
                                  color: (i + 0.5) / _bars <= f ? const Color(0xFFAEB9FF) : const Color(0x33FFFFFF),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
            SizedBox(
              width: 40,
              child: Text(fmt(total), textAlign: TextAlign.right, style: mono(TS.label, color: const Color(0x99FFFFFF))),
            ),
          ],
        );
      },
    );
  }
}

class _IslandButton extends StatelessWidget {
  const _IslandButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.size = 40,
    this.iconSize,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final double size;
  final double? iconSize;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: primary ? Colors.white : const Color(0x1FFFFFFF),
        shape: CircleBorder(
          side: primary ? BorderSide.none : const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: iconSize ?? size * 0.5,
              color: primary ? Colors.black : (tint ?? Colors.white),
            ),
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
