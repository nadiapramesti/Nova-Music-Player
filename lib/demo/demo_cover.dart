import 'dart:math';

import 'package:flutter/material.dart';

import 'demo_data.dart';

/// Cover album demo: gradien + ilustrasi geometris, digambar langsung di kode.
class DemoCover extends StatelessWidget {
  const DemoCover({super.key, required this.songId});
  final int songId;

  @override
  Widget build(BuildContext context) {
    final album = demoAlbumOfSong(songId) ?? demoAlbums.first;
    return CustomPaint(painter: _CoverPainter(album), child: const SizedBox.expand());
  }
}

class _CoverPainter extends CustomPainter {
  _CoverPainter(this.a);
  final DemoAlbum a;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    final deep = Color.lerp(a.base, Colors.black, 0.45)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(a.base, a.ink, 0.18)!, a.base, deep],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    final ink = Paint()..color = a.ink;
    final soft = Paint()..color = a.ink.withAlpha(70);
    final stroke = Paint()
      ..color = a.ink.withAlpha(170)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, w * 0.018);

    switch (a.pattern) {
      case 0: // matahari terbenam + garis cakrawala
        canvas.drawCircle(Offset(w * 0.5, h * 0.62), w * 0.26, ink);
        final band = Paint()..color = deep;
        for (var i = 0; i < 5; i++) {
          final y = h * (0.62 + i * 0.055);
          canvas.drawRect(Rect.fromLTWH(0, y, w, h * (0.012 + i * 0.006)), band);
        }
        canvas.drawRect(Rect.fromLTWH(0, h * 0.86, w, h * 0.14), Paint()..color = deep);
      case 1: // cincin orbit
        for (var i = 1; i <= 5; i++) {
          canvas.drawCircle(Offset(w * 0.42, h * 0.58), w * 0.1 * i, stroke);
        }
        canvas.drawCircle(Offset(w * 0.42 + w * 0.3, h * 0.58 - w * 0.22), w * 0.06, ink);
      case 2: // pita diagonal
        canvas.save();
        canvas.translate(w / 2, h / 2);
        canvas.rotate(-pi / 5);
        for (var i = -4; i <= 4; i++) {
          canvas.drawRect(Rect.fromLTWH(-w, i * h * 0.16, w * 2, h * 0.06), i.isEven ? soft : ink);
        }
        canvas.restore();
      case 3: // titik-titik peta + rute
        for (var x = 0; x < 7; x++) {
          for (var y = 0; y < 7; y++) {
            canvas.drawCircle(Offset(w * (0.14 + x * 0.12), h * (0.14 + y * 0.12)), w * 0.012, soft);
          }
        }
        final route = Path()
          ..moveTo(w * 0.14, h * 0.86)
          ..cubicTo(w * 0.3, h * 0.4, w * 0.62, h * 0.9, w * 0.86, h * 0.26);
        canvas.drawPath(route, stroke..strokeWidth = w * 0.03);
        canvas.drawCircle(Offset(w * 0.86, h * 0.26), w * 0.045, ink);
      case 4: // ombak
        for (var i = 0; i < 6; i++) {
          final y0 = h * (0.4 + i * 0.1);
          final wave = Path()..moveTo(0, y0);
          for (var x = 0.0; x <= w; x += w / 24) {
            wave.lineTo(x, y0 + sin(x / w * pi * 3 + i) * h * 0.03);
          }
          canvas.drawPath(wave, stroke..color = a.ink.withAlpha(90 + i * 25));
        }
        canvas.drawCircle(Offset(w * 0.74, h * 0.22), w * 0.09, ink);
      default: // lengkung lampu sein
        final arch = Path()
          ..moveTo(w * 0.2, h)
          ..lineTo(w * 0.2, h * 0.48)
          ..arcToPoint(Offset(w * 0.8, h * 0.48), radius: Radius.circular(w * 0.3))
          ..lineTo(w * 0.8, h)
          ..close();
        canvas.drawPath(arch, soft);
        canvas.drawCircle(Offset(w * 0.5, h * 0.48), w * 0.11, ink);
    }

    // Label kecil ala sampul piringan.
    final tp = TextPainter(
      text: TextSpan(
        text: a.artist.toUpperCase(),
        style: TextStyle(
          fontFamily: 'PlexMono',
          fontSize: max(6.0, w * 0.07),
          fontWeight: FontWeight.w600,
          letterSpacing: w * 0.006,
          color: a.ink.withAlpha(230),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: w * 0.84);
    if (w >= 60) tp.paint(canvas, Offset(w * 0.08, h * 0.07));
  }

  @override
  bool shouldRepaint(_CoverPainter old) => old.a != a;
}
