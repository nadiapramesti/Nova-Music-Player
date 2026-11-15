import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Satu set warna Nova. Produksi selalu pakai [Palette.dark];
/// [Palette.light] cuma buat perbandingan di mode demo.
class Palette {
  const Palette({
    required this.brightness,
    required this.bg,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.line,
    required this.rule,
    required this.track,
    required this.chip,
    required this.glass,
    required this.glassStrong,
    required this.glassLine,
    required this.cover,
    required this.coverAlt,
    required this.coverBig,
    required this.glow,
    required this.glowSoft,
    required this.scrim,
  });

  /// Palet yang sama, aksennya diganti (dipakai buat warna ikut cover).
  Palette withAccent(Color a, Color on) => Palette(
        brightness: brightness,
        bg: bg,
        text: text,
        muted: muted,
        accent: a,
        onAccent: on,
        accentSoft: a.withAlpha((accentSoft.a * 255).round()),
        line: line,
        rule: rule,
        track: track,
        chip: chip,
        glass: glass,
        glassStrong: glassStrong,
        glassLine: glassLine,
        cover: cover,
        coverAlt: coverAlt,
        coverBig: coverBig,
        glow: a.withAlpha((glow.a * 255).round()),
        glowSoft: a.withAlpha((glowSoft.a * 255).round()),
        scrim: scrim,
      );

  final Brightness brightness;
  final Color bg, text, muted, accent, onAccent, accentSoft, line, rule, track, chip;
  final Color glass, glassStrong, glassLine, cover, coverAlt, coverBig, glow, glowSoft, scrim;

  /// Gelap + kaca, satu aksen "cahaya bintang".
  static const dark = Palette(
    brightness: Brightness.dark,
    bg: Color(0xFF0A0B0F),
    text: Color(0xFFECEEF5),
    muted: Color(0xFF8F95A8),
    accent: Color(0xFFAEB9FF),
    onAccent: Color(0xFF0C1030),
    accentSoft: Color(0x24AEB9FF),
    line: Color(0x2EECEEF5),
    rule: Color(0x12ECEEF5),
    track: Color(0x24ECEEF5),
    chip: Color(0x14ECEEF5),
    glass: Color(0x10FFFFFF),
    glassStrong: Color(0x8C14161E),
    glassLine: Color(0x21FFFFFF),
    cover: Color(0x14FFFFFF),
    coverAlt: Color(0x0BFFFFFF),
    coverBig: Color(0xFF141622),
    glow: Color(0x42AEB9FF),
    glowSoft: Color(0x1FAEB9FF),
    scrim: Color(0x66000000),
  );

  /// Terang: kertas dingin, kaca susu, aksen biru tua biar kontras.
  static const light = Palette(
    brightness: Brightness.light,
    bg: Color(0xFFEEF0F6),
    text: Color(0xFF12131A),
    muted: Color(0xFF575D72),
    accent: Color(0xFF3346D3),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x1F3346D3),
    line: Color(0x3312131A),
    rule: Color(0x1412131A),
    track: Color(0x2412131A),
    chip: Color(0x0F12131A),
    glass: Color(0x8CFFFFFF),
    glassStrong: Color(0xB8F8F9FC),
    glassLine: Color(0xD9FFFFFF),
    cover: Color(0x1412131A),
    coverAlt: Color(0x0A12131A),
    coverBig: Color(0xFFDDE1EF),
    glow: Color(0x473346D3),
    glowSoft: Color(0x1F3346D3),
    scrim: Color(0x2912131A),
  );
}

/// Palet aktif. Ganti lewat [setPalette] (mode demo saja).
class Nv {
  static Palette p = Palette.dark;

  /// Palet dasar (gelap/terang) sebelum aksen ikut cover.
  static Palette base = Palette.dark;

  static Color get bg => p.bg;
  static Color get text => p.text;
  static Color get muted => p.muted;
  static Color get accent => p.accent;
  static Color get onAccent => p.onAccent;
  static Color get accentSoft => p.accentSoft;
  static Color get line => p.line;
  static Color get rule => p.rule;
  static Color get track => p.track;
  static Color get chip => p.chip;
  static Color get glass => p.glass;
  static Color get glassStrong => p.glassStrong;
  static Color get glassLine => p.glassLine;
  static Color get cover => p.cover;
  static Color get coverAlt => p.coverAlt;
  static Color get coverBig => p.coverBig;
  static Color get glow => p.glow;
  static Color get glowSoft => p.glowSoft;
  static Color get scrim => p.scrim;
  static bool get isLight => p.brightness == Brightness.light;
}

/// Dinaikkan tiap palet berganti; root app dengerin ini lalu bangun ulang semua layar.
final paletteVersion = ValueNotifier<int>(0);

/// Ganti palet dasar (mode demo). Aksen dari cover tetap dipasang di atasnya.
void setPalette(Palette palette) {
  Nv.base = palette;
  _applyPalette();
}

Color? _tint;

/// Atur terang-gelap warna cover biar tetap kebaca di palet ini.
Color tuneAccent(Color raw, Brightness brightness) {
  final hsl = HSLColor.fromColor(raw);
  if (brightness == Brightness.dark) {
    return hsl.withSaturation(hsl.saturation.clamp(0.45, 0.9)).withLightness(0.76).toColor();
  }
  return hsl.withSaturation(hsl.saturation.clamp(0.5, 0.85)).withLightness(0.4).toColor();
}

/// Teks/ikon di atas tombol beraksen.
Color onAccentFor(Color accent, Brightness brightness) {
  if (brightness == Brightness.light) return const Color(0xFFFFFFFF);
  return HSLColor.fromColor(accent).withSaturation(0.55).withLightness(0.1).toColor();
}


/// Pasang warna mentah dari cover sebagai aksen (null = balik ke biru Nova).
void setAccentTint(Color? raw) {
  if (raw == _tint) return;
  _tint = raw;
  _applyPalette();
}

void _applyPalette() {
  final base = Nv.base;
  final raw = _tint;
  Palette next = base;
  if (raw != null) {
    final a = tuneAccent(raw, base.brightness);
    next = base.withAccent(a, onAccentFor(a, base.brightness));
  }
  if (identical(Nv.p, next)) return;
  if (Nv.p.brightness == next.brightness && Nv.p.accent == next.accent && Nv.p.bg == next.bg) return;
  Nv.p = next;
  applySystemBars();
  paletteVersion.value++;
  // Warna dibaca langsung dari Nv di tiap build, jadi semua layar (termasuk widget const
  // dan layar yang lagi kebuka) ditandai buat dibangun ulang.
  WidgetsBinding.instance.rootElement?.visitChildren(_rebuildAll);
}

void _rebuildAll(Element el) {
  el.markNeedsBuild();
  el.visitChildren(_rebuildAll);
}

/// Ikon status bar & navigasi ikut terang/gelap palet.
void applySystemBars() {
  final dark = Nv.p.brightness == Brightness.dark;
  final icons = dark ? Brightness.light : Brightness.dark;
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: icons,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: icons,
  ));
}

FontWeight _fw(double w) => FontWeight.values[((w / 100).round() - 1).clamp(0, 8)];

/// Bricolage Grotesque (variable font): berat diatur lewat FontVariation.
/// Skala ukuran huruf Nova. Semua teks pakai ini biar seragam.
abstract final class TS {
  /// Info kecil di bawah judul (artis · album, keterangan).
  static const double caption = 12.5;

  /// Paragraf, deskripsi, label tombol kecil/chip.
  static const double body = 13.5;

  /// Judul baris lagu, isian form, tombol utama.
  static const double title = 15;

  /// Judul yang lebih menonjol (mini player, kartu).
  static const double lead = 17;

  /// Judul bagian.
  static const double h3 = 20;

  /// Judul lembar & layar kosong.
  static const double h2 = 24;

  /// Mono: label kapital kecil, angka/durasi.
  static const double monoTiny = 10;
  static const double label = 11;
  static const double mono = 12;
}

TextStyle disp(
  double size, {
  double w = 800,
  Color? color,
  double? height,
  double spacing = 0,
}) {
  return TextStyle(
    fontFamily: 'Bricolage',
    fontSize: size,
    fontWeight: _fw(w),
    // Bricolage punya sumbu "optical size": huruf kecil dibikin lebih lega & kebaca,
    // huruf besar lebih rapat & tegas. Tanpa ini semua ukuran pakai gaya poster (96).
    fontVariations: [FontVariation('wght', w), FontVariation('opsz', size.clamp(12, 96).toDouble())],
    color: color ?? Nv.text,
    height: height,
    letterSpacing: spacing,
  );
}

/// IBM Plex Mono buat angka, durasi, label kecil.
TextStyle mono(double size, {double w = 600, Color? color, double spacing = 0}) {
  return TextStyle(
    fontFamily: 'PlexMono',
    fontSize: size,
    fontWeight: w >= 600 ? FontWeight.w600 : FontWeight.w500,
    color: color ?? Nv.muted,
    letterSpacing: spacing,
  );
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Nv.p.brightness,
    scaffoldBackgroundColor: Nv.bg,
    fontFamily: 'Bricolage',
    colorScheme: ColorScheme.fromSeed(
      seedColor: Nv.accent,
      brightness: Nv.p.brightness,
    ).copyWith(
      primary: Nv.accent,
      onPrimary: Nv.onAccent,
      surface: Nv.bg,
      onSurface: Nv.text,
    ),
    splashFactory: InkRipple.splashFactory,
    progressIndicatorTheme: ProgressIndicatorThemeData(color: Nv.accent),
    textSelectionTheme: TextSelectionThemeData(
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
    this.color,
  });

  final double? top;
  final double? left;
  final double? right;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Nv.glow;
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
              colors: [c, c.withAlpha(0)],
              stops: const [0, 0.7],
            ),
          ),
        ),
      ),
    );
  }
}
