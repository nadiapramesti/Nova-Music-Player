import 'dart:ui';

import 'package:flutter/material.dart';

/// Palet Nova: netral gelap + satu aksen "cahaya bintang".
class Nv {
  static const bg = Color(0xFF0A0B0F);
  static const text = Color(0xFFECEEF5);
  static const muted = Color(0xFF8F95A8);
  static const accent = Color(0xFFAEB9FF);
  static const onAccent = Color(0xFF0C1030);
  static const accentSoft = Color(0x24AEB9FF);
  static const line = Color(0x2EECEEF5);
  static const rule = Color(0x12ECEEF5);
  static const track = Color(0x24ECEEF5);
  static const chip = Color(0x14ECEEF5);
  static const glass = Color(0x10FFFFFF);
  static const glassStrong = Color(0x8C14161E);
  static const glassLine = Color(0x21FFFFFF);
  static const cover = Color(0x14FFFFFF);
  static const coverAlt = Color(0x0BFFFFFF);
  static const coverBig = Color(0xFF141622);
  static const glow = Color(0x42AEB9FF);
  static const glowSoft = Color(0x1FAEB9FF);
}

FontWeight _fw(double w) => FontWeight.values[((w / 100).round() - 1).clamp(0, 8)];

/// Bricolage Grotesque (variable font): berat diatur lewat FontVariation.
TextStyle disp(
  double size, {
  double w = 800,
  Color color = Nv.text,
  double? height,
  double spacing = 0,
}) {
  return TextStyle(
    fontFamily: 'Bricolage',
    fontSize: size,
    fontWeight: _fw(w),
    fontVariations: [FontVariation('wght', w)],
    color: color,
    height: height,
    letterSpacing: spacing,
  );
}

/// IBM Plex Mono buat angka, durasi, label kecil.
TextStyle mono(double size, {double w = 600, Color color = Nv.muted, double spacing = 0}) {
  return TextStyle(
    fontFamily: 'PlexMono',
    fontSize: size,
    fontWeight: w >= 600 ? FontWeight.w600 : FontWeight.w500,
    color: color,
    letterSpacing: spacing,
  );
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Nv.bg,
    fontFamily: 'Bricolage',
    colorScheme: const ColorScheme.dark(
      primary: Nv.accent,
      onPrimary: Nv.onAccent,
      surface: Nv.bg,
      onSurface: Nv.text,
    ),
    splashFactory: InkRipple.splashFactory,
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Nv.accent),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Nv.accent,
      selectionColor: Nv.accentSoft,
      selectionHandleColor: Nv.accent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      modalBackgroundColor: Colors.transparent,
    ),
  );
}

/// Panel kaca buram.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = EdgeInsets.zero,
    this.strong = false,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool strong;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: strong ? 26 : 20, sigmaY: strong ? 26 : 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? (strong ? Nv.glassStrong : Nv.glass),
            borderRadius: r,
            border: Border.all(color: borderColor ?? Nv.glassLine),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Cahaya bulat samar di latar, biar kacanya "kebaca".
class Glow extends StatelessWidget {
  const Glow({
    super.key,
    this.top,
    this.left,
    this.right,
    this.size = 360,
    this.color = Nv.glow,
  });

  final double? top;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withAlpha(0)],
              stops: const [0, 0.7],
            ),
          ),
        ),
      ),
    );
  }
}
