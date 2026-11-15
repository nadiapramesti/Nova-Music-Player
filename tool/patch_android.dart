// Siapin folder android/ hasil `flutter create` buat Nova:
// izin audio, service background, dan MainActivity (channel MediaStore).
// Jalankan dari root project:  dart tool/patch_android.dart
import 'dart:io';

const _perms = [
  '<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>',
  '<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>',
  '<uses-permission android:name="android.permission.WAKE_LOCK"/>',
  '<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>',
  '<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>',
  '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
  '<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>',
];

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
    <item android:drawable="@drawable/ic_launcher_fg" android:gravity="center"
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
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/ic_launcher_fg</item>
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

// ---- Ikon launcher: headset + bintang (adaptive icon, Android 8+) ----
const _iconFg = '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#00000000" android:strokeColor="#ECEEF5"
        android:strokeWidth="5" android:strokeLineCap="round"
        android:pathData="M34,60 L34,52 A20,20 0 0 1 74,52 L74,60"/>
    <path android:fillColor="#ECEEF5"
        android:pathData="M32,56h4a4,4 0 0 1 4,4v12a4,4 0 0 1 -4,4h-4a4,4 0 0 1 -4,-4v-12a4,4 0 0 1 4,-4z"/>
    <path android:fillColor="#ECEEF5"
        android:pathData="M72,56h4a4,4 0 0 1 4,4v12a4,4 0 0 1 -4,4h-4a4,4 0 0 1 -4,-4v-12a4,4 0 0 1 4,-4z"/>
    <group android:translateX="45" android:translateY="55" android:scaleX="0.75" android:scaleY="0.75">
        <path android:fillColor="#AEB9FF"
            android:pathData="M12,1.5C12.6,7.1 16.9,11.4 22.5,12C16.9,12.6 12.6,16.9 12,22.5C11.4,16.9 7.1,12.6 1.5,12C7.1,11.4 11.4,7.1 12,1.5Z"/>
    </group>
</vector>
''';

const _iconBg = '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#0A0B0F" android:pathData="M0,0h108v108h-108z"/>
    <path android:pathData="M0,0h108v108h-108z">
        <aapt:attr name="android:fillColor">
            <gradient android:type="radial" android:centerX="54" android:centerY="44"
                android:gradientRadius="58" android:startColor="#3C4479" android:endColor="#000A0B0F"/>
        </aapt:attr>
    </path>
</vector>
''';

const _adaptive = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_bg"/>
    <foreground android:drawable="@drawable/ic_launcher_fg"/>
    <monochrome android:drawable="@drawable/ic_launcher_fg"/>
</adaptive-icon>
''';

// ---- Layanan Aksesibilitas (opsional): pulau tipis di notch yang bisa di-tap ----
const _a11yService = '''
        <service
            android:name=".NovaIslandService"
            android:label="Nova · Pulau di notch"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
            android:exported="true">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService"/>
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/nova_accessibility"/>
        </service>
''';

const _a11yXml = '''<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:notificationTimeout="500"
    android:canRetrieveWindowContent="false"
    android:description="@string/nova_a11y_desc"/>
''';

const _strings = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="nova_a11y_desc">Dipakai Nova cuma buat nampilin pulau lagu di notch kamera (di atas status bar) supaya bisa di-tap. Nova gak membaca isi layar atau ketikan.</string>
</resources>
''';

void patchAccessibility(String manifestPath) {
  final f = File(manifestPath);
  var m = f.readAsStringSync();
  if (!m.contains('NovaIslandService')) {
    m = m.replaceFirst('</application>', '$_a11yService    </application>');
    f.writeAsStringSync(m);
  }
  const res = 'android/app/src/main/res';
  _write('$res/xml/nova_accessibility.xml', _a11yXml);
  _write('$res/values/nova_strings.xml', _strings);
  stdout.writeln('+ layanan Aksesibilitas pulau di notch');
}

// ---- Izin HTTP cuma ke 127.0.0.1: audio senyap mode demo diputar lewat proxy lokal just_audio ----
const _netConfig = '''<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">127.0.0.1</domain>
        <domain includeSubdomains="false">localhost</domain>
    </domain-config>
</network-security-config>
''';

void patchNetworkConfig(String manifestPath) {
  _write('android/app/src/main/res/xml/network_security_config.xml', _netConfig);
  final f = File(manifestPath);
  final m = f.readAsStringSync();
  if (!m.contains('networkSecurityConfig')) {
    f.writeAsStringSync(m.replaceFirst(
      '<application',
      '<application\n        android:networkSecurityConfig="@xml/network_security_config"',
    ));
  }
  stdout.writeln('+ HTTP lokal (127.0.0.1) buat audio mode demo');
}

void unpatchAccessibility(String manifestPath) {
  final f = File(manifestPath);
  final m = f.readAsStringSync();
  final cleaned = m.replaceAll(_a11yService, '');
  if (cleaned != m) {
    f.writeAsStringSync(cleaned);
    stdout.writeln('- layanan Aksesibilitas dilepas (biar gak diblok Play Protect)');
  }
}

void patchIcon() {
  const res = 'android/app/src/main/res';
  _write('$res/drawable/ic_launcher_fg.xml', _iconFg);
  _write('$res/drawable/ic_launcher_bg.xml', _iconBg);
  _write('$res/mipmap-anydpi-v26/ic_launcher.xml', _adaptive);
  // PNG lama (Android < 8) diganti versi Nova kalau ada di tool/icons/.
  for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
    final src = File('tool/icons/ic_launcher-$d.png');
    if (src.existsSync()) src.copySync('$res/mipmap-$d/ic_launcher.png');
  }
  stdout.writeln('+ ikon launcher headset + bintang');
}

void main(List<String> args) {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln('Folder android/ belum ada. Jalankan dulu:\n'
        '  flutter create --org com.nadia --project-name nova --platforms android .');
    exit(1);
  }

  var m = manifest.readAsStringSync();
  for (final perm in _perms) {
    final name = RegExp(r'android:name="([^"]+)"').firstMatch(perm)!.group(1)!;
    if (!m.contains('"$name"')) {
      m = m.replaceFirst('<application', '$perm\n    <application');
      stdout.writeln('+ izin ${name.split('.').last}');
    }
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
  patchIcon();
  patchNetworkConfig(manifest.path);
  // Layanan Aksesibilitas bikin APK sideload diblok Play Protect, jadi cuma dipasang
  // kalau diminta:  dart tool/patch_android.dart --a11y
  if (args.contains('--a11y')) {
    patchAccessibility(manifest.path);
  } else {
    unpatchAccessibility(manifest.path);
  }

  stdout.writeln('Beres. Lanjut: flutter pub get');
}
