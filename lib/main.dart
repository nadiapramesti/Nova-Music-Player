import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'screens/shell.dart';
import 'screens/splash_screen.dart';
import 'services/services.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Notifikasi + kontrol di lockscreen; lagu tetap jalan pas layar mati.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.nadia.nova.audio',
    androidNotificationChannelName: 'Pemutar Nova',
    androidNotificationOngoing: true,
  );
  await stats.init();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const NovaApp());
}

class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashGate(child: Shell()),
    );
  }
}
