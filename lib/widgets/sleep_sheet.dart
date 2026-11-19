import 'package:flutter/material.dart';

import '../services/services.dart';
import '../services/sleep_timer.dart';
import '../theme.dart';
import 'controls.dart';

/// Lembar pilihan timer tidur.
void showSleepSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.sheet,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, MediaQuery.of(context).padding.bottom + 8),
      child: Glass(
        strong: true,
        radius: 28,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: ListenableBuilder(
          listenable: audio.sleep.listenable,
          builder: (context, _) {
            final t = audio.sleep;
            final left = t.left.value;
            final status = left != null
                ? 'Musik berhenti dalam ${formatCountdown(left)}'
                : t.endOfTrack.value
                    ? 'Musik berhenti setelah lagu ini selesai'
                    : 'Musik berhenti sendiri, volumenya turun pelan dulu.';
            void pick(VoidCallback start) {
              start();
              Navigator.of(context).pop();
            }

            final options = <(String, String, VoidCallback)>[
              ('15', 'menit', () => t.start(const Duration(minutes: 15))),
              ('30', 'menit', () => t.start(const Duration(minutes: 30))),
              ('45', 'menit', () => t.start(const Duration(minutes: 45))),
              ('60', 'menit', () => t.start(const Duration(minutes: 60))),
              ('90', 'menit', () => t.start(const Duration(minutes: 90))),
              ('Akhir', 'lagu ini', t.startEndOfTrack),
            ];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TIMER TIDUR', style: mono(TS.label, spacing: 1.2)),
                const SizedBox(height: 4),
                Text('Berhenti otomatis', style: disp(TS.h2, spacing: -0.6)),
                const SizedBox(height: 6),
                Text(status,
                    style: disp(TS.body, w: 600, color: t.active ? Nv.accent : Nv.muted, height: 1.35)),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.55,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final (big, small, start) in options)
                      _Choice(big: big, small: small, onTap: () => pick(start)),
                  ],
                ),
                if (t.active) ...[
                  const SizedBox(height: 14),
                  WideButton(
                    label: 'Matikan timer',
                    icon: Icons.close_rounded,
                    primary: false,
                    onTap: () {
                      t.cancel();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({required this.big, required this.small, required this.onTap});
  final String big;
  final String small;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);
    return Material(
      color: Nv.chip,
      shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: Nv.line, width: 1.2)),
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(big, style: disp(TS.h3, spacing: -0.5)),
            Text(small, style: mono(TS.label)),
          ],
        ),
      ),
    );
  }
}
