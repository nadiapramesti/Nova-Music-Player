import 'package:flutter/material.dart';

import '../theme.dart';

/// Bintang empat sudut di logo Nova.
class NovaStar extends StatelessWidget {
  const NovaStar({super.key, this.size = 18, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _StarPainter(color ?? Nv.accent));
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

/// Logo Nova: headset + bintang kecil di tengah.
class NovaMark extends StatelessWidget {
  const NovaMark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MarkPainter());
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Digambar di kotak 56 unit (bagian tengah ikon launcher 108 unit).
    final k = size.width / 56;
    Offset p(double x, double y) => Offset((x - 26) * k, (y - 26) * k);

    final band = Path()
      ..moveTo(p(34, 60).dx, p(34, 60).dy)
      ..lineTo(p(34, 52).dx, p(34, 52).dy)
      ..arcToPoint(p(74, 52), radius: Radius.circular(20 * k), clockwise: true)
      ..lineTo(p(74, 60).dx, p(74, 60).dy);
    canvas.drawPath(
      band,
      Paint()
        ..color = Nv.text
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * k
        ..strokeCap = StrokeCap.round,
    );

    final cup = Paint()..color = Nv.text;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromPoints(p(28, 56), p(40, 76)), Radius.circular(4 * k)), cup);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromPoints(p(68, 56), p(80, 76)), Radius.circular(4 * k)), cup);

    // Bintang 24 unit, digeser ke (45,55) dan diperkecil 0.75.
    Offset s(double x, double y) => p(45 + x * 0.75, 55 + y * 0.75);
    final star = Path()..moveTo(s(12, 1.5).dx, s(12, 1.5).dy);
    void c(double a, double b, double cc, double d, double e, double f) {
      final p1 = s(a, b), p2 = s(cc, d), p3 = s(e, f);
      star.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
    }

    c(12.6, 7.1, 16.9, 11.4, 22.5, 12);
    c(16.9, 12.6, 12.6, 16.9, 12, 22.5);
    c(11.4, 16.9, 7.1, 12.6, 1.5, 12);
    c(7.1, 11.4, 11.4, 7.1, 12, 1.5);
    star.close();
    canvas.drawPath(star, Paint()..color = Nv.accent);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => false;
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
    this.fg,
    this.border,
    this.radius,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final double size;
  final double iconSize;
  final Color fill;
  final Color? fg;
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
          child: SizedBox.square(dimension: size, child: Icon(icon, size: iconSize, color: fg ?? Nv.text)),
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
        side: selected ? BorderSide.none : BorderSide(color: Nv.line, width: 1.5),
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
              Text(label, style: disp(TS.caption, w: 700, color: selected ? Nv.bg : Nv.text)),
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
        side: primary ? BorderSide.none : BorderSide(color: Nv.line, width: 1.5),
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
              Text(label, style: disp(TS.title, w: 800, color: primary ? Nv.onAccent : Nv.text)),
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
          Expanded(child: Text(title, style: disp(TS.h2, spacing: -0.6))),
          if (trailing != null) Text(trailing!, style: mono(TS.mono)),
        ],
      ),
    );
  }
}
