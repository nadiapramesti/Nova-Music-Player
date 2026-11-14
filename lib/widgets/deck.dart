import 'package:flutter/material.dart';

import '../theme.dart';

/// Dek kaca di bawah: navigasi Putar / Rak / Cari.
/// Lagu yang lagi diputar pindah ke pulau di notch (lihat island.dart).
class Deck extends StatelessWidget {
  const Deck({super.key, required this.tab, required this.onTab});

  final int tab;
  final ValueChanged<int> onTab;

  static const tabs = ['Putar', 'Rak', 'Cari'];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 14))],
      ),
      child: Glass(
        strong: true,
        radius: 26,
        padding: const EdgeInsets.all(7),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(child: _NavPill(label: tabs[i], active: i == tab, onTap: () => onTab(i))),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(19);
    return Material(
      color: active ? Nv.text : Nv.chip,
      borderRadius: r,
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(label, style: disp(13.5, w: active ? 800 : 700, color: active ? Nv.bg : Nv.text)),
          ),
        ),
      ),
    );
  }
}
