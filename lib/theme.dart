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

  /// Merah buat aksi yang gak bisa dibalikin (hapus file).
  static Color get danger => isLight ? const Color(0xFFC6283B) : const Color(0xFFFF7A86);
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

/// Huruf Nova (gaya editorial, kayak sampul majalah musik):
/// - judul (>= TS.h3): Instrument Serif — ramping & elegan, cuma satu ketebalan
/// - teks lain: Instrument Sans (variable, tebal 400–700)
/// Angka/label kecil tetap pakai [mono].
TextStyle disp(
  double size, {
  double w = 800,
  Color? color,
  double? height,
  double spacing = 0,
  bool italic = false,
}) {
  if (size >= TS.h3) {
    return TextStyle(
      fontFamily: 'InstrumentSerif',
      // Serif ini kelihatan lebih kecil dari sans di ukuran yang sama.
      fontSize: size * 1.16,
      fontWeight: FontWeight.w400,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color ?? Nv.text,
      height: height,
      // Jarak rapat ala sans tebal bikin serif dempet: dilonggarin.
      letterSpacing: spacing * 0.25,
    );
  }
  final wt = w.clamp(400, 700).toDouble();
  return TextStyle(
    fontFamily: 'InstrumentSans',
    fontSize: size,
    fontWeight: _fw(wt),
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    fontVariations: [FontVariation('wght', wt)],
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

/// Gerak Nova: kurva & durasi yang sama di semua transisi biar terasa satu app.
abstract final class Motion {
  /// Masuk: cepat di awal, mendarat pelan (emphasized decelerate).
  static const enter = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Keluar: mulai pelan, makin cepat (emphasized accelerate).
  static const exit = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Gerak biasa di tempat (pudar, geser kecil).
  static const standard = Cubic(0.2, 0.0, 0.0, 1.0);

  static const fast = Duration(milliseconds: 200);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 420);

  /// Semua lembar bawah (aksi lagu, antrean, pengaturan, timer, equalizer).
  static const sheet = AnimationStyle(
    duration: Duration(milliseconds: 380),
    reverseDuration: Duration(milliseconds: 240),
    curve: enter,
    reverseCurve: exit,
  );
}

/// Pindah halaman (album, artis, playlist): halaman baru geser masuk sedikit
/// sambil muncul, halaman lama minggir sedikit sambil pudar.
class NovaPageTransitions extends PageTransitionsBuilder {
  const NovaPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final inSlide = CurvedAnimation(parent: animation, curve: Motion.enter, reverseCurve: Motion.exit);
    final inFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
      reverseCurve: const Interval(0.3, 1, curve: Curves.easeIn),
    );
    final outMove = CurvedAnimation(parent: secondaryAnimation, curve: Motion.standard);
    return SlideTransition(
      position: Tween(begin: Offset.zero, end: const Offset(-0.05, 0)).animate(outMove),
      child: FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.35).animate(outMove),
        child: FadeTransition(
          opacity: inFade,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.07, 0), end: Offset.zero).animate(inSlide),
            child: child,
          ),
        ),
      ),
    );
  }
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Nv.p.brightness,
    scaffoldBackgroundColor: Nv.bg,
    fontFamily: 'InstrumentSans',
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
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: NovaPageTransitions(),
      TargetPlatform.iOS: NovaPageTransitions(),
    }),
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
