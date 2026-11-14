# Nova

Pemutar musik lokal untuk Android. Muter lagu yang udah ada di HP: **offline, tanpa iklan, tanpa akun**.

Tema gelap dengan panel kaca, satu aksen "cahaya bintang".

## Fitur

- Baca semua lagu di HP (MP3, M4A, FLAC, dll.) langsung dari MediaStore Android
- **Putar**: daftar lagu bernomor, urut Terbaru / Terlama / A–Z, acak, kartu "Lanjutkan"
- **Rak**: kelompokkan per Album, Artis, Folder, dan Favorit
- **Cari**: cari judul/artis/album, riwayat pencarian, pintasan *Paling sering diputar*, *Lama gak didengar*, *Baru masuk HP*, *Favorit*
- **Sedang diputar**: cover dari tag file, seek bar gelombang, acak, ulangi, antrean
- Kontrol di notifikasi & lockscreen, tetap jalan saat layar mati
- Statistik putar & favorit disimpan lokal di HP

## Download APK

Tiap push ke `main`, GitHub Actions nge-build APK otomatis.
Ambil `nova.apk` di tab **Releases**, lalu install di HP (izinkan "install dari sumber tidak dikenal").

## Jalankan di laptop

```bash
git clone https://github.com/nadiapramesti/Nova-Music-Player.git
cd Nova-Music-Player
flutter create --org com.nadia --project-name nova --platforms android .
dart tool/patch_android.dart
flutter pub get
flutter analyze
flutter run
```

Folder `android/` sengaja gak di-commit; dibuat ulang lewat dua perintah di atas.

## Struktur

- `lib/services/` baca lagu (channel `nova/media`), player, statistik & favorit
- `lib/screens/` Putar, Rak, Cari, Sedang diputar, daftar lagu
- `lib/widgets/` dek kaca, baris lagu, cover, tombol
- `tool/MainActivity.kt.template` kode Android buat baca MediaStore + cover
- `tool/patch_android.dart` izin, service background, MainActivity

## Kredit

- Dibuat oleh Nadia Pramesti, dibantu Claude (Anthropic) sebagai pair-programmer.
- Font: [Bricolage Grotesque](https://fonts.google.com/specimen/Bricolage+Grotesque) dan [IBM Plex Mono](https://fonts.google.com/specimen/IBM+Plex+Mono), lisensi SIL Open Font License (lihat `assets/fonts/`).
