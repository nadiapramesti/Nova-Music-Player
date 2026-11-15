import 'package:flutter/material.dart';

import '../services/services.dart';
import '../theme.dart';
import 'controls.dart';

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, MediaQuery.of(context).padding.bottom + 8),
      child: Glass(
        strong: true,
        radius: 28,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: SingleChildScrollView(child: ListenableBuilder(
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
                body: 'Pil ikut muncul di atas app lain. Tap pil = kartu lagu, geser ke atas = '
                    'sembunyi jadi titik kecil, tap titiknya = muncul lagi. Tahan = buka Nova.',
                value: island.outside,
                onChanged: island.setOutside,
              ),
              const SizedBox(height: 10),
              _Toggle(
                title: 'Mode presisi di notch (Aksesibilitas)',
                body: island.precise
                    ? 'Aktif. Pil tipis duduk pas di lubang kamera dan bisa di-tap, di dalam maupun di luar app.'
                    : 'Biar pil tipis bisa nempel pas di kamera dan tetap bisa di-tap (kayak Auralys), '
                        'aktifin "Nova · Pulau di notch" di Aksesibilitas. Nova gak baca isi layar.',
                value: island.precise,
                onChanged: (_) => island.openAccessibility(),
              ),
              const SizedBox(height: 12),
              const _OutsideTester(),
            ],
          ),
        )),
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

/// Status izin + tombol tes pil di luar app.
class _OutsideTester extends StatefulWidget {
  const _OutsideTester();

  @override
  State<_OutsideTester> createState() => _OutsideTesterState();
}

class _OutsideTesterState extends State<_OutsideTester> with WidgetsBindingObserver {
  String? _msg;
  bool? _granted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final ok = await island.canDraw();
    if (mounted) setState(() => _granted = ok);
  }

  Future<void> _test() async {
    final err = await island.test();
    await _check();
    if (!mounted) return;
    setState(() => _msg = err ?? 'Pil muncul 5 detik di notch. Kalau gak keliatan, cek petunjuk di bawah.');
  }

  @override
  Widget build(BuildContext context) {
    final granted = _granted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              granted == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              size: 18,
              color: granted == true ? Nv.accent : Nv.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                granted == null
                    ? 'Ngecek izin…'
                    : granted
                        ? 'Izin tampil di atas aplikasi lain: aktif'
                        : 'Izin tampil di atas aplikasi lain: belum aktif',
                style: disp(13, w: 600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (granted == false) ...[
          WideButton(
            label: 'Buka halaman izin',
            icon: Icons.open_in_new_rounded,
            onTap: () async {
              await island.requestPermission();
            },
          ),
          const SizedBox(height: 8),
        ],
        WideButton(label: 'Coba pil sekarang', icon: Icons.bolt_rounded, primary: false, onTap: _test),
        if (_msg != null) ...[
          const SizedBox(height: 8),
          Text(_msg!, style: disp(12.5, w: 600, color: Nv.accent, height: 1.35)),
        ],
        const SizedBox(height: 8),
        Text(
          'Kalau saklar Aksesibilitas Nova abu-abu (gak bisa dinyalain): buka Pengaturan › '
          'Aplikasi › Nova › titik tiga di pojok › "Izinkan setelan terbatas", lalu coba lagi. '
          'Di Oppo/Realme, matikan juga optimasi baterai buat Nova.',
          style: disp(12, w: 500, color: Nv.muted, height: 1.4),
        ),
      ],
    );
  }
}
