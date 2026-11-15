// Diagnosa: putar lagu demo lalu diam 90 detik, biar skrip host bisa ngecek
// sesi media, notifikasi, dan layar kunci lewat adb (lihat tool/diag_media.sh).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nova/main.dart' as app;
import 'package:nova/services/services.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sesi media', (tester) async {
    await app.main();
    await _wait(tester, 6);
    if (audio.current.value == null) {
      await audio.playQueue(library.songs, 0, from: 'Diagnosa');
    }
    await audio.player.play();
    // ignore: avoid_print
    print('NOVA_PLAYING ${audio.player.playing} ${audio.current.value?.title}');
    await _wait(tester, 90);
  });
}

Future<void> _wait(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
