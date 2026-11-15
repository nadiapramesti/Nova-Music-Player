import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'demo/demo.dart';
import 'screens/shell.dart';
import 'screens/splash_screen.dart';
import 'services/services.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Notifikasi + kontrol di lockscreen; lagu tetap jalan pas layar mati.
  // Sesi audio "musik": kayak app musik lain, Nova minggir kalau app lain bunyi
  // (video TikTok/SW WA → jeda; telepon → jeda lalu lanjut sendiri; notifikasi →
  // suara dikecilin sebentar; headset dicabut → jeda).
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.nadia.nova.audio',
    androidNotificationChannelName: 'Pemutar Nova',
    androidNotificationOngoing: true,
  );
  await stats.init();
  await playlists.init();
  await island.init(audio, stats);
  await audio.initPlayback();
  await coverTint.init();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Produksi selalu gelap. Mode demo bisa mulai terang: --dart-define=DEMO_THEME=light
  if (kDemo && kDemoTheme == 'light') Nv.p = Nv.base = Palette.light;
  applySystemBars();

  runApp(const NovaApp());
}

class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: paletteVersion,
      builder: (context, _, __) => MaterialApp(
        title: 'Nova',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashGate(child: Shell()),
      ),
    );
  }
}
