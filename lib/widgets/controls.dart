import 'package:flutter/material.dart';

import '../theme.dart';

/// Bintang empat sudut di logo Nova.
class NovaStar extends StatelessWidget {
  const NovaStar({super.key, this.size = 18, this.color = Nv.accent});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _StarPainter(color));
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    Offset p(double x, double y) => Offset(x * k, y * k);
    final a = p(12, 1.5), b = p(22.5, 12), c = p(12, 22.5), d = p(1.5, 12);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(p(12.6, 7.1).dx, p(12.6, 7.1).dy, p(16.9, 11.4).dx, p(16.9, 11.4).dy, b.dx, b.dy)
      ..cubicTo(p(16.9, 12.6).dx, p(16.9, 12.6).dy, p(12.6, 16.9).dx, p(12.6, 16.9).dy, c.dx, c.dy)
      ..cubicTo(p(11.4, 16.9).dx, p(11.4, 16.9).dy, p(7.1, 12.6).dx, p(7.1, 12.6).dy, d.dx, d.dy)
      ..cubicTo(p(7.1, 11.4).dx, p(7.1, 11.4).dy, p(11.4, 7.1).dx, p(11.4, 7.1).dy, a.dx, a.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

/// Tombol bulat kaca (tutup, antrean, dll).
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.label,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Glass(
        radius: size / 2,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: size,
              child: Icon(icon, size: 21, color: Nv.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol bulat solid / outline.
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.label,
    this.size = 48,
    this.iconSize = 22,
    this.fill = Colors.transparent,
    this.fg = Nv.text,
    this.border,
    this.radius,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final double size;
  final double iconSize;
  final Color fill;
  final Color fg;
  final Color? border;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? size / 2);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: r,
          side: border == null ? BorderSide.none : BorderSide(color: border!, width: 1.5),
        ),
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: SizedBox.square(dimension: size, child: Icon(icon, size: iconSize, color: fg)),
        ),
      ),
    );
  }
}

/// Pil filter: terpilih = isi terang, lainnya = outline.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.height = 34,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(height / 2);
    return Material(
      color: selected ? Nv.text : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: r,
        side: selected ? BorderSide.none : const BorderSide(color: Nv.line, width: 1.5),
      ),
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: selected ? Nv.bg : Nv.text),
                const SizedBox(width: 5),
              ],
              Text(label, style: disp(12.5, w: 700, color: selected ? Nv.bg : Nv.text)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol aksi lebar (Putar semua / Acak).
class WideButton extends StatelessWidget {
  const WideButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);
    return Material(
      color: primary ? Nv.accent : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: r,
        side: primary ? BorderSide.none : const BorderSide(color: Nv.line, width: 1.5),
      ),
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: primary ? Nv.onAccent : Nv.text),
              const SizedBox(width: 8),
              Text(label, style: disp(15, w: 800, color: primary ? Nv.onAccent : Nv.text)),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: disp(22, spacing: -0.6))),
          if (trailing != null) Text(trailing!, style: mono(12)),
        ],
      ),
    );
  }
}
