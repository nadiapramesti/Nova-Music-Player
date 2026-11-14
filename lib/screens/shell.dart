import 'package:flutter/material.dart';

import '../services/services.dart';
import '../widgets/deck.dart';
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

  static const _pages = [HomeScreen(), ShelfScreen(), SearchScreen()];

  @override
  void initState() {
    super.initState();
    // Minta izin + baca lagu setelah layar pertama tampil.
    WidgetsBinding.instance.addPostFrameCallback((_) => library.load());
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return PopScope(
      // Tombol back di tab lain = balik ke Putar dulu.
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Semua tab tetap hidup (scroll & isian gak ke-reset),
            // pindahnya pakai geser + pudar ke arah tab tujuan.
            for (var i = 0; i < _pages.length; i++)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: i != _tab,
                  child: TickerMode(
                    enabled: i == _tab,
                    child: AnimatedSlide(
                      offset: i == _tab ? Offset.zero : Offset(i < _tab ? -0.08 : 0.08, 0),
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: i == _tab ? 1 : 0,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                        child: _pages[i],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: bottom + 12,
              child: Deck(tab: _tab, onTab: (i) => setState(() => _tab = i)),
            ),
            const Positioned.fill(child: NowIsland()),
          ],
        ),
      ),
    );
  }
}
