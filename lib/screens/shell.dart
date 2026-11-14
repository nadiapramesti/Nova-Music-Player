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
            IndexedStack(
              index: _tab,
              children: const [HomeScreen(), ShelfScreen(), SearchScreen()],
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
