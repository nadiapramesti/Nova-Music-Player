// Siapin folder android/ hasil `flutter create` buat Nova:
// izin audio, service background, dan MainActivity (channel MediaStore).
// Jalankan dari root project:  dart tool/patch_android.dart
import 'dart:io';

const _perms = '''
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
''';

const _service = '''
        <service
            android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService"/>
            </intent-filter>
        </service>
        <receiver
            android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON"/>
            </intent-filter>
        </receiver>
''';

// ---- Splash bawaan Android (sebelum Flutter jalan) ----
const _star = '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <group android:translateX="34" android:translateY="34" android:scaleX="1.6667" android:scaleY="1.6667">
        <path android:fillColor="#AEB9FF"
            android:pathData="M12,1.5C12.6,7.1 16.9,11.4 22.5,12C16.9,12.6 12.6,16.9 12,22.5C11.4,16.9 7.1,12.6 1.5,12C7.1,11.4 11.4,7.1 12,1.5Z"/>
    </group>
</vector>
''';

const _launchBg = '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/nova_bg"/>
    <item android:drawable="@drawable/nova_star" android:gravity="center"
        android:width="108dp" android:height="108dp"/>
</layer-list>
''';

const _colors = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="nova_bg">#0A0B0F</color>
</resources>
''';

const _styles = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/nova_bg</item>
    </style>
</resources>
''';

const _styles31 = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/nova_bg</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/nova_star</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/nova_bg</item>
    </style>
</resources>
''';

void _write(String path, String content) {
  final f = File(path);
  f.parent.createSync(recursive: true);
  f.writeAsStringSync(content);
}

void patchSplash() {
  const res = 'android/app/src/main/res';
  _write('$res/drawable/nova_star.xml', _star);
  _write('$res/values/nova_colors.xml', _colors);
  _write('$res/drawable/launch_background.xml', _launchBg);
  _write('$res/drawable-v21/launch_background.xml', _launchBg);
  _write('$res/values/styles.xml', _styles);
  _write('$res/values-night/styles.xml', _styles);
  _write('$res/values-v31/styles.xml', _styles31);
  _write('$res/values-night-v31/styles.xml', _styles31);
  stdout.writeln('+ splash gelap + bintang Nova');
}

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln('Folder android/ belum ada. Jalankan dulu:\n'
        '  flutter create --org com.nadia --project-name nova --platforms android .');
    exit(1);
  }

  var m = manifest.readAsStringSync();
  if (!m.contains('READ_MEDIA_AUDIO')) {
    m = m.replaceFirst('<application', '$_perms\n    <application');
    stdout.writeln('+ izin audio');
  }
  if (!m.contains('com.ryanheise.audioservice.AudioService')) {
    m = m.replaceFirst('</application>', '$_service    </application>');
    stdout.writeln('+ service background');
  }
  m = m.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="Nova"');
  manifest.writeAsStringSync(m);

  final template = File('tool/MainActivity.kt.template').readAsStringSync();
  var found = false;
  for (final f in Directory('android/app/src/main').listSync(recursive: true)) {
    if (f is File && f.path.endsWith('MainActivity.kt')) {
      final pkg = RegExp(r'^package .*$', multiLine: true).firstMatch(f.readAsStringSync())?.group(0);
      f.writeAsStringSync(pkg == null ? template : template.replaceFirst('package com.nadia.nova', pkg));
      stdout.writeln('+ MainActivity (channel nova/media)');
      found = true;
    }
  }
  if (!found) {
    stderr.writeln('! MainActivity.kt gak ketemu.');
    exit(1);
  }

  // Test bawaan flutter create masih nyebut MyApp, bikin analyze error.
  final t = File('test/widget_test.dart');
  if (t.existsSync() && t.readAsStringSync().contains('MyApp')) {
    t.deleteSync();
    stdout.writeln('+ test/widget_test.dart bawaan dihapus');
  }

  patchSplash();

  stdout.writeln('Beres. Lanjut: flutter pub get');
}
