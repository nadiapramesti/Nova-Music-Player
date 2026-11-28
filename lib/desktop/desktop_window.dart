import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../models.dart';
import '../services/services.dart';
import '../theme.dart';
import '../widgets/art.dart';

enum IslandStage { handle, pill, card }

/// Jendela Nova di laptop: bilah judul sendiri (biar nyatu sama tema), dan
/// "pulau" — jendela kecil melayang di atas app lain, kayak pulau notch di HP.
class DesktopWindow extends ChangeNotifier with WindowListener {
  DesktopWindow._();
  static final instance = DesktopWindow._();

  /// Lagi jadi pulau (jendela utama ngumpet).
  bool island = false;
  IslandStage stage = IslandStage.pill;

  /// Tombol X = jadi pulau (musik tetap jalan). Mati = X nutup Nova.
  bool closeToIsland = true;

  Rect? _normalBounds;

  /// Titik tengah-atas pulau (bisa digeser pengguna).
  Offset? _anchor;
  Timer? _idle;

  static const _sizes = {
    IslandStage.handle: Size(170, 24),
    IslandStage.pill: Size(360, 60),
    IslandStage.card: Size(400, 214),
  };

  Future<void> setup() async {
    await windowManager.ensureInitialized();
    final p = await SharedPreferences.getInstance();
    closeToIsland = p.getBool('deskCloseToIsland') ?? true;
    final ax = p.getDouble('deskIslandX'), ay = p.getDouble('deskIslandY');
    if (ax != null && ay != null) _anchor = Offset(ax, ay);
    const opts = WindowOptions(
      size: Size(480, 880),
      minimumSize: Size(380, 620),
      center: true,
      title: 'Nova',
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Color(0xFF0A0B0F),
    );
    await windowManager.waitUntilReadyToShow(opts, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
    audio.current.addListener(_wake);
    audio.player.playingStream.listen((_) => _wake());
  }

  Future<void> setCloseToIsland(bool v) async {
    closeToIsland = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool('deskCloseToIsland', v);
  }

  @override
  void onWindowClose() async {
    if (island) return;
    if (closeToIsland && audio.current.value != null) {
      await enterIsland();
    } else {
      await quit();
    }
  }

  Future<void> quit() async {
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
    exit(0);
  }

  // ---- Pulau ----

  Future<void> enterIsland() async {
    if (island) return;
    _normalBounds = await windowManager.getBounds();
    island = true;
    stage = IslandStage.pill;
    notifyListeners();
    await windowManager.setResizable(false);
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(false);
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);
    await _applyStage();
    _restartIdle();
  }

  Future<void> exitIsland() async {
    if (!island) return;
    _idle?.cancel();
    island = false;
    notifyListeners();
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setBackgroundColor(Nv.bg);
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setHasShadow(true);
    await windowManager.setResizable(true);
    final b = _normalBounds;
    if (b != null) {
      await windowManager.setBounds(b);
    } else {
      await windowManager.setSize(const Size(480, 880));
      await windowManager.center();
    }
    await windowManager.focus();
  }

  Future<void> setStage(IslandStage s) async {
    if (!island || stage == s) return;
    stage = s;
    notifyListeners();
    await _applyStage();
  }

  Future<void> _applyStage() async {
    final size = _sizes[stage]!;
    final anchor = _anchor ?? await _defaultAnchor();
    await windowManager.setSize(size);
    await windowManager.setPosition(Offset(anchor.dx - size.width / 2, anchor.dy));
  }

  Future<Offset> _defaultAnchor() async {
    // Tengah atas layar utama (ukuran logis).
    final view = PlatformDispatcher.instance.views.first;
    final w = view.display.size.width / view.display.devicePixelRatio;
    return Offset(w / 2, 8);
  }

  /// Habis digeser: simpan titik tengah-atasnya.
  Future<void> rememberPosition() async {
    final b = await windowManager.getBounds();
    _anchor = Offset(b.left + b.width / 2, b.top);
    final p = await SharedPreferences.getInstance();
    await p.setDouble('deskIslandX', _anchor!.dx);
    await p.setDouble('deskIslandY', _anchor!.dy);
  }

  void _wake() {
    if (!island) return;
    if (stage == IslandStage.handle) setStage(IslandStage.pill);
    _restartIdle();
  }

  /// Gak disentuh 4 detik → ngumpet jadi garis kecil.
  void _restartIdle() {
    _idle?.cancel();
    _idle = Timer(const Duration(seconds: 4), () {
      if (island && stage == IslandStage.pill) setStage(IslandStage.handle);
    });
  }

  void hover(bool inside) {
    if (!island) return;
    if (inside) {
      _idle?.cancel();
      if (stage == IslandStage.handle) setStage(IslandStage.pill);
    } else {
      _idle?.cancel();
      _idle = Timer(const Duration(milliseconds: 1200), () {
        if (!island) return;
        if (stage == IslandStage.card) {
          setStage(IslandStage.pill);
          _restartIdle();
        } else {
          _restartIdle();
        }
      });
    }
  }
}

/// Bungkus seluruh app di laptop: bilah judul + isi; atau pulau kalau lagi mode pulau.
/// Isi app tetap hidup (Offstage) selama jadi pulau, jadi gak kehilangan posisi/state.
class DesktopFrame extends StatelessWidget {
  const DesktopFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final w = DesktopWindow.instance;
    return ListenableBuilder(
      listenable: w,
      builder: (context, _) => Stack(
        children: [
          Offstage(
            offstage: w.island,
            child: ColoredBox(
              color: Nv.bg,
              child: Column(children: [const _TitleBar(), Expanded(child: child)]),
            ),
          ),
          if (w.island) const Positioned.fill(child: _IslandView()),
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Icon(Icons.headphones_rounded, size: 16, color: Nv.accent),
                    const SizedBox(width: 8),
                    Text('nova', style: disp(TS.title, w: 700)),
                  ],
                ),
              ),
            ),
          ),
          _WinButton(
            icon: Icons.picture_in_picture_alt_rounded,
            tip: 'Jadi pulau',
            onTap: () => DesktopWindow.instance.enterIsland(),
          ),
          _WinButton(icon: Icons.remove_rounded, tip: 'Kecilkan', onTap: () => windowManager.minimize()),
          _WinButton(
            icon: Icons.crop_square_rounded,
            tip: 'Besarkan',
            onTap: () async => await windowManager.isMaximized() ? windowManager.unmaximize() : windowManager.maximize(),
          ),
          _WinButton(icon: Icons.close_rounded, tip: 'Tutup', danger: true, onTap: () => windowManager.close()),
        ],
      ),
    );
  }
}

class _WinButton extends StatelessWidget {
  const _WinButton({required this.icon, required this.tip, required this.onTap, this.danger = false});
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        hoverColor: danger ? const Color(0xFFC42B1C) : Nv.chip,
        child: SizedBox(width: 46, height: 40, child: Icon(icon, size: 17, color: Nv.text)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulau melayang
// ---------------------------------------------------------------------------

class _IslandView extends StatelessWidget {
  const _IslandView();

  @override
  Widget build(BuildContext context) {
    final w = DesktopWindow.instance;
    return Material(
      type: MaterialType.transparency,
      child: MouseRegion(
        onEnter: (_) => w.hover(true),
        onExit: (_) => w.hover(false),
        child: GestureDetector(
          // Geser ke mana aja (tahan & seret), posisinya diingat.
          onPanStart: (_) => windowManager.startDragging(),
          onPanEnd: (_) => w.rememberPosition(),
          child: ValueListenableBuilder<Song?>(
            valueListenable: audio.current,
            builder: (context, song, _) => AnimatedSwitcher(
              duration: Motion.fast,
              child: switch (w.stage) {
                IslandStage.handle => _Handle(key: const ValueKey('h'), onTap: () => w.setStage(IslandStage.pill)),
                IslandStage.pill => _Pill(key: const ValueKey('p'), song: song, onTap: () => w.setStage(IslandStage.card)),
                IslandStage.card => _Card(key: const ValueKey('c'), song: song),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Glassy extends StatelessWidget {
  const _Glassy({required this.child, this.radius = 30, this.padding = EdgeInsets.zero});
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Nv.bg.withAlpha(242),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Nv.line),
      ),
      child: child,
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 150,
          height: 10,
          decoration: BoxDecoration(
            color: Nv.bg.withAlpha(235),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Nv.accent.withAlpha(150)),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.song, required this.onTap});
  final Song? song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = song;
    return GestureDetector(
      onTap: onTap,
      child: _Glassy(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: [
            if (s != null) Art(songId: s.id, size: 42, radius: 21) else const SizedBox(width: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s?.title ?? 'Nova', maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.body, w: 700)),
                  Text(s?.artist ?? 'Belum ada lagu',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.caption, w: 500, color: Nv.muted)),
                ],
              ),
            ),
            _PlayButton(size: 40),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.song});
  final Song? song;

  @override
  Widget build(BuildContext context) {
    final s = song;
    return _Glassy(
      radius: 28,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (s != null) Art(songId: s.id, size: 72, radius: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s?.title ?? 'Nova', maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.title, w: 700)),
                    const SizedBox(height: 2),
                    Text(s?.artist ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.caption, w: 500, color: Nv.muted)),
                    const SizedBox(height: 8),
                    const _Progress(),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _IconBtn(icon: Icons.skip_previous_rounded, tip: 'Sebelumnya', onTap: () => audio.player.seekToPrevious()),
              const SizedBox(width: 6),
              _PlayButton(size: 44),
              const SizedBox(width: 6),
              _IconBtn(icon: Icons.skip_next_rounded, tip: 'Berikutnya', onTap: () => audio.player.seekToNext()),
              const Spacer(),
              _TextBtn(label: 'Buka Nova', onTap: () => DesktopWindow.instance.exitIsland()),
              const SizedBox(width: 6),
              _IconBtn(icon: Icons.power_settings_new_rounded, tip: 'Keluar Nova', onTap: () => DesktopWindow.instance.quit()),
            ],
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: audio.player.positionStream,
      builder: (context, snap) {
        final total = audio.player.duration ?? Duration.zero;
        final pos = snap.data ?? Duration.zero;
        final f = total.inMilliseconds <= 0 ? 0.0 : (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: f, minHeight: 4, color: Nv.accent, backgroundColor: Nv.track),
            ),
            const SizedBox(height: 4),
            Text('${fmt(pos)} / ${fmt(total)}', style: mono(TS.monoTiny)),
          ],
        );
      },
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: audio.player.playingStream,
      initialData: audio.player.playing,
      builder: (context, snap) {
        final playing = snap.data ?? false;
        return Tooltip(
          message: playing ? 'Jeda' : 'Putar',
          child: Material(
            color: Nv.accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: audio.togglePlay,
              child: SizedBox.square(
                dimension: size,
                child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Nv.onAccent, size: size * 0.55),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.tip, required this.onTap});
  final IconData icon;
  final String tip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: Material(
        color: Nv.chip,
        shape: CircleBorder(side: BorderSide(color: Nv.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(dimension: 38, child: Icon(icon, size: 20, color: Nv.text)),
        ),
      ),
    );
  }
}

class _TextBtn extends StatelessWidget {
  const _TextBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(19);
    return Material(
      color: Nv.chip,
      shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: Nv.line)),
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(label, style: disp(TS.body, w: 700)),
        ),
      ),
    );
  }
}
