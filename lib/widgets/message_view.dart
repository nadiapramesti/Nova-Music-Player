import 'package:flutter/material.dart';

import '../theme.dart';

class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Glow(top: 120, left: -60, size: 420),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Glass(
                  radius: 44,
                  child: SizedBox.square(dimension: 88, child: Icon(icon, size: 36, color: Nv.accent)),
                ),
                const SizedBox(height: 22),
                Text(title, textAlign: TextAlign.center, style: disp(26, spacing: -0.8)),
                const SizedBox(height: 8),
                Text(body,
                    textAlign: TextAlign.center,
                    style: disp(14, w: 500, color: Nv.muted, height: 1.4)),
                const SizedBox(height: 26),
                for (final a in actions) ...[a, const SizedBox(height: 10)],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
