import 'dart:async';

import 'package:flutter/material.dart';

import '../services/services.dart';
import '../theme.dart';
import 'controls.dart';
import 'song_actions.dart';

/// Tombol "muter di mana" di layar pemutar: HP ini / nama TV.
class CastChip extends StatelessWidget {
  const CastChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cast,
      builder: (context, _) {
        final on = cast.state != CastState.idle;
        final label = switch (cast.state) {
          CastState.idle => 'Putar di TV',
          CastState.connecting => 'Nyambung ke ${cast.device?.name ?? 'TV'}…',
          CastState.casting => 'Di ${cast.device?.name ?? 'TV'}',
        };
        final r = BorderRadius.circular(22);
        return Material(
          color: on ? Nv.accentSoft : Nv.chip,
          shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: on ? Nv.accent : Nv.line)),
          child: InkWell(
            borderRadius: r,
            onTap: () => showCastSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(on ? Icons.cast_connected_rounded : Icons.cast_rounded, size: 18, color: on ? Nv.accent : Nv.text),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: disp(TS.body, w: 700, color: on ? Nv.accent : Nv.text)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void showCastSheet(BuildContext context) {
  showGlassSheet<void>(context, (_) => const _CastBody());
}

class _CastBody extends StatefulWidget {
  const _CastBody();

  @override
  State<_CastBody> createState() => _CastBodyState();
}

class _CastBodyState extends State<_CastBody> {
  Timer? _giveUp;
  bool _waitedLong = false;

  @override
  void initState() {
    super.initState();
    if (cast.state == CastState.idle) _scan();
  }

  void _scan() {
    _waitedLong = false;
    cast.startScan();
    _giveUp?.cancel();
    _giveUp = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _waitedLong = true);
    });
  }

  @override
  void dispose() {
    _giveUp?.cancel();
    cast.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cast,
      builder: (context, _) {
        final list = cast.devices.values.toList()..sort((a, b) => a.name.compareTo(b.name));
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PUTAR DI', style: mono(TS.label, spacing: 1.2)),
            const SizedBox(height: 4),
            Text('Pilih perangkat', style: disp(TS.h2, spacing: -0.6)),
            const SizedBox(height: 6),
            Text(
              'TV yang ada Chromecast / Google TV di WiFi yang sama. Lagunya dikirim dari HP, gak lewat internet.',
              style: disp(TS.caption, w: 500, color: Nv.muted, height: 1.35),
            ),
            const SizedBox(height: 14),
            _DeviceRow(
              icon: Icons.smartphone_rounded,
              name: 'HP ini',
              sub: cast.state == CastState.idle ? 'Lagi muter di sini' : 'Balik muter di HP',
              selected: cast.state == CastState.idle,
              onTap: cast.state == CastState.idle ? null : () => cast.disconnect(),
            ),
            for (final d in list)
              _DeviceRow(
                icon: Icons.tv_rounded,
                name: d.name,
                sub: cast.device?.id == d.id && cast.state == CastState.connecting
                    ? 'Nyambung…'
                    : cast.device?.id == d.id && cast.casting
                        ? 'Lagi muter di sini'
                        : (d.model.isEmpty ? 'Chromecast' : d.model),
                selected: cast.device?.id == d.id && cast.state != CastState.idle,
                busy: cast.device?.id == d.id && cast.state == CastState.connecting,
                onTap: cast.device?.id == d.id && cast.state != CastState.idle ? null : () => cast.connect(d),
              ),
            if (cast.state == CastState.casting && cast.device != null && list.every((d) => d.id != cast.device!.id))
              _DeviceRow(icon: Icons.tv_rounded, name: cast.device!.name, sub: 'Lagi muter di sini', selected: true),
            if (cast.error != null) ...[
              const SizedBox(height: 4),
              Text(cast.error!, style: disp(TS.caption, w: 600, color: Nv.danger, height: 1.35)),
            ],
            const SizedBox(height: 10),
            if (cast.state == CastState.idle && list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    if (!_waitedLong)
                      SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Nv.accent))
                    else
                      Icon(Icons.tv_off_rounded, size: 18, color: Nv.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _waitedLong
                            ? 'TV belum ketemu. Cek: HP & TV di WiFi yang sama, TV-nya nyala, dan ada Chromecast / Google TV.'
                            : 'Nyari TV di WiFi…',
                        style: disp(TS.caption, w: 500, color: Nv.muted, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            if (cast.casting)
              WideButton(label: 'Putus & balik ke HP', icon: Icons.cast_rounded, onTap: () => cast.disconnect())
            else
              WideButton(label: 'Cari ulang', icon: Icons.refresh_rounded, primary: false, onTap: _scan),
          ],
        );
      },
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.icon,
    required this.name,
    required this.sub,
    this.selected = false,
    this.busy = false,
    this.onTap,
  });

  final IconData icon;
  final String name;
  final String sub;
  final bool selected;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? Nv.accentSoft : Nv.chip,
        shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: selected ? Nv.accent : Nv.line)),
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: selected ? Nv.accent : Nv.text),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.title, w: 700)),
                      Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.caption, w: 500, color: Nv.muted)),
                    ],
                  ),
                ),
                if (busy)
                  SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Nv.accent))
                else if (selected)
                  Icon(Icons.check_circle_rounded, size: 20, color: Nv.accent)
                else
                  Icon(Icons.chevron_right_rounded, size: 22, color: Nv.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
