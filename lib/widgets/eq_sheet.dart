import 'package:flutter/material.dart';

import '../services/equalizer.dart';
import '../services/services.dart';
import '../theme.dart';
import 'controls.dart';
import 'song_actions.dart';

/// Lembar equalizer: nyala/mati, preset, dan geser tiap band.
void showEqSheet(BuildContext context) {
  showGlassSheet<void>(context, (_) => const _EqBody());
}

class _EqBody extends StatefulWidget {
  const _EqBody();

  @override
  State<_EqBody> createState() => _EqBodyState();
}

class _EqBodyState extends State<_EqBody> {
  late final Future<void> _ready = equalizer.ready();

  /// Nilai band yang lagi digeser (biar mulus, baru dikirim pas dilepas).
  final Map<int, double> _dragging = {};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: equalizer,
      builder: (context, _) {
        final st = equalizer.settings;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SUARA', style: mono(TS.label, spacing: 1.2)),
                      const SizedBox(height: 4),
                      Text('Equalizer', style: disp(TS.h2, spacing: -0.6)),
                    ],
                  ),
                ),
                Switch(
                  value: st.enabled,
                  activeThumbColor: Nv.onAccent,
                  activeTrackColor: Nv.accent,
                  onChanged: (v) => equalizer.setEnabled(v),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in [...eqPresets.keys, if (st.preset == 'Custom') 'Custom']) ...[
                    Pill(
                      label: p == 'Custom' ? 'Atur sendiri' : p,
                      selected: st.enabled && st.preset == p,
                      onTap: () => p == 'Custom' ? equalizer.setEnabled(true) : equalizer.setPreset(p),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<void>(
              future: _ready,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: Nv.accent)),
                  );
                }
                final p = equalizer.params;
                if (p == null) {
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'Puter lagu dulu, baru equalizer bisa diatur.',
                        textAlign: TextAlign.center,
                        style: disp(TS.body, w: 500, color: Nv.muted),
                      ),
                    ),
                  );
                }
                final gains = equalizer.gains;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: st.enabled ? 1 : 0.45,
                  child: SizedBox(
                    height: 220,
                    child: Row(
                      children: [
                        for (var i = 0; i < p.bands.length; i++)
                          Expanded(
                            child: _Band(
                              label: hzLabel(p.bands[i].centerFrequency),
                              value: _dragging[i] ?? (i < gains.length ? gains[i] : 0),
                              min: p.minDecibels,
                              max: p.maxDecibels,
                              onChanged: (v) => setState(() => _dragging[i] = v),
                              onChangeEnd: (v) async {
                                await equalizer.setBand(i, v);
                                if (mounted) setState(() => _dragging.remove(i));
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            WideButton(
              label: 'Balikin datar',
              icon: Icons.horizontal_rule_rounded,
              primary: false,
              onTap: () => equalizer.setPreset('Normal'),
            ),
          ],
        );
      },
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged, onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final db = value.round();
    return Column(
      children: [
        Text(db > 0 ? '+$db' : '$db', style: mono(TS.monoTiny, color: db == 0 ? Nv.muted : Nv.accent)),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: Nv.accent,
                inactiveTrackColor: Nv.track,
                thumbColor: Nv.text,
                overlayColor: Nv.accentSoft,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ),
        ),
        Text(label, style: mono(TS.monoTiny)),
      ],
    );
  }
}
