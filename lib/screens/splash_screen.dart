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
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
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
    final glow = _seg(0.0, 0.7);
    final star = _seg(0.1, 0.55, Curves.easeOutBack);
    final word = _seg(0.35, 0.75);
    final tag = _seg(0.55, 0.9);

    return Scaffold(
      key: const ValueKey('splash'),
      backgroundColor: Nv.bg,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: glow.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.4 + glow.value * 0.9,
                  child: Container(
                    width: 460,
                    height: 460,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x59AEB9FF), Color(0x00AEB9FF)],
                        stops: [0, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: (1 - star.value) * 1.6,
                    child: Transform.scale(
                      scale: star.value.clamp(0.0, 1.2),
                      child: const NovaStar(size: 64),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: word.value,
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - word.value)),
                      child: Text('nova', style: disp(48, spacing: -1.8)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: tag.value,
                    child: Text('OFFLINE · TANPA IKLAN', style: mono(11.5, spacing: 1.6)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
