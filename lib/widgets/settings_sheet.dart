import 'package:flutter/material.dart';

import '../services/services.dart';
import '../theme.dart';

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, MediaQuery.of(context).padding.bottom + 8),
      child: Glass(
        strong: true,
        radius: 28,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: ListenableBuilder(
          listenable: island,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PENGATURAN', style: mono(11, spacing: 1.2)),
              const SizedBox(height: 4),
              Text('Pulau di notch', style: disp(24, spacing: -0.6)),
              const SizedBox(height: 14),
              _Toggle(
                title: 'Tampil di dalam Nova',
                body: 'Pil lagu di area kamera. Tap buat kontrol, geser ke atas buat sembunyiin.',
                value: island.inApp,
                onChanged: island.setInApp,
              ),
              const SizedBox(height: 10),
              _Toggle(
                title: 'Tetap tampil di luar app',
                body: 'Pil ikut muncul di atas app lain. Butuh izin "Tampil di atas aplikasi lain". '
                    'Tap = buka Nova, tahan atau geser ke atas = sembunyiin.',
                value: island.outside,
                onChanged: island.setOutside,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.title, required this.body, required this.value, required this.onChanged});

  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Nv.chip,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: disp(15, w: 700)),
                    const SizedBox(height: 3),
                    Text(body, style: disp(12.5, w: 500, color: Nv.muted, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Nv.onAccent,
                activeTrackColor: Nv.accent,
                inactiveThumbColor: Nv.muted,
                inactiveTrackColor: Nv.chip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
