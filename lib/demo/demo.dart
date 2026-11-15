/// Mode demo buat screenshot promosi.
///
/// Aktif HANYA kalau dijalankan dengan `--dart-define=DEMO=true`.
/// Tanpa flag ini semua nilai di bawah `false`/default dan app jalan normal
/// (baca lagu lokal di HP).
///
/// Opsi tambahan: `--dart-define=DEMO_THEME=light` buat langsung mulai di tema terang.
library;

const bool kDemo = bool.fromEnvironment('DEMO');
/// Build khusus dengan layanan Aksesibilitas (lihat tool/patch_android.dart --a11y).
/// APK sideload yang punya Aksesibilitas diblok Play Protect, jadi default-nya mati.
const bool kA11y = bool.fromEnvironment('A11Y');

const String kDemoTheme = String.fromEnvironment('DEMO_THEME', defaultValue: 'dark');
