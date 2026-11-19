/// Mode demo buat screenshot promosi.
///
/// Aktif HANYA kalau dijalankan dengan `--dart-define=DEMO=true`.
/// Tanpa flag ini semua nilai di bawah `false`/default dan app jalan normal
/// (baca lagu lokal di HP).
///
/// Opsi tambahan: `--dart-define=DEMO_THEME=light` buat langsung mulai di tema terang.
library;

const bool kDemo = bool.fromEnvironment('DEMO');

const String kDemoTheme = String.fromEnvironment('DEMO_THEME', defaultValue: 'dark');
