// Ambil screenshot promosi Nova di mode demo.
// Jalankan (butuh HP/emulator Android):
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart --dart-define=DEMO=true
// Hasil: folder screenshots/
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nova/main.dart' as app;
import 'package:nova/services/services.dart';
import 'package:nova/theme.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot promosi', (tester) async {
    await app.main();
    // Splash (~1,9 dtk) + transisi + lagu demo mulai jalan.
    await _wait(tester, 6);
    await binding.convertFlutterSurfaceToImage();
    await _wait(tester, 1);

    // 1) Pustaka lagu
    await binding.takeScreenshot('1-pustaka-lagu');

    // 2) Pemutar, tema gelap: tap cover di pemutar mini (satu-satunya Hero di layar utama).
    if (audio.current.value == null) {
      await audio.playQueue(library.songs, 2, from: 'Daftar putar · Terbaru');
      await _wait(tester, 2);
    }
    await tester.tap(find.byType(Hero).first);
    await _wait(tester, 2);
    await binding.takeScreenshot('2-pemutar-gelap');

    // 3) Antrean
    await tester.tap(find.byIcon(Icons.queue_music_rounded));
    await _wait(tester, 2);
    await binding.takeScreenshot('3-antrean');

    // Tutup antrean (tap area gelap di atas lembar).
    await tester.tapAt(const Offset(200, 120));
    await _wait(tester, 2);

    // 4) Pemutar, tema terang
    setPalette(Palette.light);
    await _wait(tester, 2);
    await binding.takeScreenshot('4-pemutar-terang');
  });
}

/// Jangan pakai pumpAndSettle: equalizer & lagu demo animasi terus.
Future<void> _wait(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
