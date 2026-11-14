import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/controls.dart';

/// Intro singkat pas app dibuka: cahaya mekar, bintang muncul, lalu "nova".
/// Setelah selesai, pindah halus ke [child].
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});
  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _seg(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      child: _done ? widget.child : _splash(),
    );
  }

  Widget _splash() {
    final glow = _seg(0.0, 0.55);
    final mark = _seg(0.05, 0.45, Curves.easeOutBack);
    final word = _seg(0.3, 0.6);
    final slogan = _seg(0.45, 0.75);

    return Scaffold(
      key: const ValueKey('splash'),
      backgroundColor: Nv.bg,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Cahaya "nova" di tengah layar, mekar pelan.
              Center(
                child: Opacity(
                  opacity: glow.value,
                  child: Transform.scale(
                    scale: 0.6 + glow.value * 0.6,
                    child: Container(
                      width: 520,
                      height: 520,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0x47AEB9FF), Color(0x00AEB9FF)],
                          stops: [0, 0.68],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: mark.value,
                      child: const NovaMark(size: 104),
                    ),
                    const SizedBox(height: 22),
                    Opacity(
                      opacity: word.value,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - word.value)),
                        child: Text('nova', style: disp(52, spacing: -2, height: 1)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Opacity(
                      opacity: slogan.value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - slogan.value)),
                        child: Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'Musikmu, '),
                            TextSpan(text: 'tanpa jeda.', style: disp(19, w: 700, color: Nv.accent)),
                          ]),
                          style: disp(19, w: 600, color: Nv.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
