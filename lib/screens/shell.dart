import 'package:flutter/material.dart';

import '../demo/demo.dart';
import '../services/services.dart';
import '../widgets/deck.dart';
import '../theme.dart';
import '../widgets/island.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'shelf_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  int _prev = 0;

  void _go(int i) {
    if (i == _tab) return;
    setState(() {
      _prev = _tab;
      _tab = i;
    });
  }

  static const _pages = [HomeScreen(), ShelfScreen(), SearchScreen()];

  @override
  void initState() {
    super.initState();
    // Minta izin + baca lagu setelah layar pertama tampil.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await library.load();
      if (kDemo) {
        _startDemoPlayback();
      } else {
        await audio.restoreLast(library.songs);
      }
    });
  }

  /// Mode demo: satu lagu langsung jalan dengan progres sekitar setengah,
  /// antrean = seluruh daftar, biar layar pemutar & antrean langsung terisi.
  Future<void> _startDemoPlayback() async {
    final songs = library.songs;
    if (songs.length < 3) return;
    const index = 2;
    try {
      await audio.playQueue(
        songs,
        index,
        from: 'Daftar putar · Terbaru',
        startAt: Duration(milliseconds: (songs[index].durationMs * 0.46).round()),
      );
    } catch (e) {
      debugPrint('Demo: gagal mulai audio senyap: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return PopScope(
      // Tombol back di tab lain = balik ke Putar dulu.
      // Back di tab lain = balik ke Putar. Back di Putar = Nova ke belakang,
      // musik tetap jalan (app gak ditutup).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_tab != 0) {
          _go(0);
        } else {
          library.moveToBack();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Semua tab tetap hidup (scroll & isian gak ke-reset),
            // pindahnya pakai geser + pudar ke arah tab tujuan.
            for (var i = 0; i < _pages.length; i++)
              Positioned.fill(
                child: _TabPage(active: i == _tab, fromLeft: i < _prev, child: _pages[i]),
              ),
            // Pudar di bawah: isi daftar gak keliatan nyelip di bawah/sela dek.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bottom + 150,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Nv.bg.withAlpha(0), Nv.bg.withAlpha(235), Nv.bg],
                      stops: const [0, 0.55, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: bottom + 12,
              child: Deck(tab: _tab, onTab: _go),
            ),
            const Positioned.fill(child: NowIsland()),
          ],
        ),
      ),
    );
  }
}

/// Satu tab: geser + pudar saat pindah, lalu benar-benar disembunyikan (Offstage)
/// setelah animasi keluar selesai. State halaman tetap hidup.
class _TabPage extends StatefulWidget {
  const _TabPage({required this.active, required this.fromLeft, required this.child});
  final bool active;
  final bool fromLeft;
  final Widget child;

  @override
  State<_TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<_TabPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: widget.active ? 1 : 0,
  );
  late final Animation<double> _in = CurvedAnimation(parent: _c, curve: Motion.enter);

  @override
  void didUpdateWidget(_TabPage old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      if (widget.active) {
        _c.forward(from: 0);
      } else {
        // Halaman yang ditinggal langsung disembunyiin: gak ada dua halaman kaca
        // buram yang digambar barengan, jadi pindah tab tetap mulus di HP.
        _c.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        final hidden = !widget.active && _c.value == 0;
        final v = _in.value;
        final dx = (1 - v) * (widget.fromLeft ? -16.0 : 16.0);
        return Offstage(
          offstage: hidden,
          child: IgnorePointer(
            ignoring: !widget.active,
            child: TickerMode(
              enabled: !hidden,
              child: v >= 1
                  ? child!
                  : Opacity(
                      opacity: v,
                      child: Transform.translate(offset: Offset(dx, 0), child: child),
                    ),
            ),
          ),
        );
      },
    );
  }
}
