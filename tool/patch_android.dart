// Siapin folder android/ hasil `flutter create` buat Nova:
// izin audio, service background, dan MainActivity (channel MediaStore).
// Jalankan dari root project:  dart tool/patch_android.dart
import 'dart:io';

const _perms = [
  '<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>',
  // Hapus lagu di Android 9 ke bawah (Android 10+ pakai dialog konfirmasi bawaan).
  '<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>',
  // Cast ke TV: cari Chromecast di WiFi & kirim lagu dari HP ke TV (jaringan lokal).
  '<uses-permission android:name="android.permission.INTERNET"/>',
  '<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>',
  '<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>',
  '<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE"/>',
  '<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>',
  '<uses-permission android:name="android.permission.WAKE_LOCK"/>',
  '<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>',
  '<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>',
  '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
  '<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>',
  // Opsional, diminta lewat tombol: baca file .lrc di samping lagu (Android 11+).
  '<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>',
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

// ---- Widget layar utama: cover + judul + tombol putar ----
const _widgetReceiver = '''
        <receiver
            android:name=".NovaWidget"
            android:label="Nova"
            android:exported="false">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/nova_widget_info"/>
        </receiver>
''';

const _widgetInfo = '''<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="64dp"
    android:minResizeWidth="200dp"
    android:targetCellWidth="4"
    android:targetCellHeight="1"
    android:resizeMode="horizontal"
    android:widgetCategory="home_screen"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/nova_widget"
    android:previewLayout="@layout/nova_widget"
    android:description="@string/nova_widget_desc"/>
''';

const _widgetLayout = '''<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/w_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/nova_widget_bg"
    android:gravity="center_vertical"
    android:orientation="horizontal"
    android:paddingStart="10dp"
    android:paddingTop="8dp"
    android:paddingEnd="8dp"
    android:paddingBottom="8dp">

    <ImageView
        android:id="@+id/w_cover"
        android:layout_width="52dp"
        android:layout_height="52dp"
        android:contentDescription="Buka Nova"
        android:scaleType="centerCrop"
        android:src="@drawable/nova_widget_cover"/>

    <LinearLayout
        android:id="@+id/w_info"
        android:layout_width="0dp"
        android:layout_height="match_parent"
        android:layout_marginStart="12dp"
        android:layout_marginEnd="4dp"
        android:layout_weight="1"
        android:gravity="center_vertical"
        android:orientation="vertical">

        <TextView
            android:id="@+id/w_status"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:fontFamily="monospace"
            android:letterSpacing="0.14"
            android:maxLines="1"
            android:text="NOVA"
            android:textColor="#AEB9FF"
            android:textSize="9sp"
            android:textStyle="bold"/>

        <TextView
            android:id="@+id/w_title"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="2dp"
            android:ellipsize="end"
            android:maxLines="1"
            android:text="Musikmu, tanpa jeda."
            android:textColor="#ECEEF5"
            android:textSize="15sp"
            android:textStyle="bold"/>

        <TextView
            android:id="@+id/w_artist"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:text="Tap buat buka Nova"
            android:textColor="#8F95A8"
            android:textSize="12sp"/>
    </LinearLayout>

    <ImageView
        android:id="@+id/w_prev"
        android:layout_width="38dp"
        android:layout_height="38dp"
        android:background="@drawable/nova_widget_btn"
        android:contentDescription="Lagu sebelumnya"
        android:padding="9dp"
        android:src="@drawable/nova_widget_prev"/>

    <ImageView
        android:id="@+id/w_play"
        android:layout_width="46dp"
        android:layout_height="46dp"
        android:layout_marginStart="6dp"
        android:layout_marginEnd="6dp"
        android:contentDescription="Putar"
        android:src="@drawable/nova_widget_play"/>

    <ImageView
        android:id="@+id/w_next"
        android:layout_width="38dp"
        android:layout_height="38dp"
        android:background="@drawable/nova_widget_btn"
        android:contentDescription="Lagu berikutnya"
        android:padding="9dp"
        android:src="@drawable/nova_widget_next"/>
</LinearLayout>
''';

const _widgetBg = '''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#EB12141C"/>
    <stroke android:width="1dp" android:color="#24FFFFFF"/>
    <corners android:radius="26dp"/>
</shape>
''';

const _widgetBtn = '''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="oval">
    <solid android:color="#14FFFFFF"/>
    <stroke android:width="1dp" android:color="#21FFFFFF"/>
</shape>
''';

const _widgetCover = '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <gradient android:angle="315" android:startColor="#3C4479" android:endColor="#141622"/>
            <corners android:radius="14dp"/>
        </shape>
    </item>
    <item android:drawable="@drawable/nova_star" android:gravity="center"
        android:width="40dp" android:height="40dp"/>
</layer-list>
''';

const _widgetPlay = '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="oval"><solid android:color="#AEB9FF"/></shape>
    </item>
    <item android:drawable="@drawable/nova_widget_play_icon" android:gravity="center"
        android:width="20dp" android:height="20dp"/>
</layer-list>
''';

const _widgetPlayIcon = '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#0C1030" android:pathData="M8,5.5v13l10.5,-6.5z"/>
</vector>
''';

const _widgetPrev = '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#ECEEF5" android:pathData="M6,6h2v12H6zM9.5,12l8.5,6V6z"/>
</vector>
''';

const _widgetNext = '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#ECEEF5" android:pathData="M6,18l8.5,-6L6,6v12zM16,6v12h2V6h-2z"/>
</vector>
''';

const _widgetStrings = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="nova_widget_desc">Lagu yang lagi diputar, plus tombol putar dan pindah lagu.</string>
</resources>
''';

void patchWidget(String manifestPath) {
  const res = 'android/app/src/main/res';
  _write('$res/xml/nova_widget_info.xml', _widgetInfo);
  _write('$res/layout/nova_widget.xml', _widgetLayout);
  _write('$res/drawable/nova_widget_bg.xml', _widgetBg);
  _write('$res/drawable/nova_widget_btn.xml', _widgetBtn);
  _write('$res/drawable/nova_widget_cover.xml', _widgetCover);
  _write('$res/drawable/nova_widget_play.xml', _widgetPlay);
  _write('$res/drawable/nova_widget_play_icon.xml', _widgetPlayIcon);
  _write('$res/drawable/nova_widget_prev.xml', _widgetPrev);
  _write('$res/drawable/nova_widget_next.xml', _widgetNext);
  _write('$res/values/nova_widget_strings.xml', _widgetStrings);
  final f = File(manifestPath);
  final m = f.readAsStringSync();
  if (!m.contains('.NovaWidget')) {
    f.writeAsStringSync(m.replaceFirst('</application>', '$_widgetReceiver    </application>'));
  }
  stdout.writeln('+ widget layar utama');
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

/// Pasang kunci tanda tangan permanen kalau android/key.properties ada
/// (ditulis CI dari secret NOVA_KEY_PASSWORD). Tanpa itu tetap pakai kunci debug.
void patchSigning() {
  if (!File('android/key.properties').existsSync()) {
    stdout.writeln('- kunci tanda tangan: gak ada, pakai kunci debug');
    return;
  }
  final f = File('android/app/build.gradle.kts');
  var g = f.readAsStringSync();
  if (g.contains('novaRelease')) return;
  // `java.util...` gak bisa langsung di skrip Gradle (kebaca ekstensi `java`), jadi di-import.
  const props = """
val novaKeyProps = Properties().apply {
    FileInputStream(rootProject.file("key.properties")).use { stream -> load(stream) }
}
""";
  g = 'import java.io.FileInputStream\nimport java.util.Properties\n\n$g';
  g = g.replaceFirst('android {', '${props}\nandroid {');
  const config = """
    signingConfigs {
        create("novaRelease") {
            storeFile = file(novaKeyProps.getProperty("storeFile"))
            storePassword = novaKeyProps.getProperty("storePassword")
            keyAlias = novaKeyProps.getProperty("keyAlias")
            keyPassword = novaKeyProps.getProperty("keyPassword")
        }
    }

    buildTypes {""";
  if (!g.contains('    buildTypes {')) throw StateError('build.gradle.kts: blok buildTypes gak ketemu');
  g = g.replaceFirst('    buildTypes {', config);
  final debugSign = RegExp(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)');
  if (!debugSign.hasMatch(g)) throw StateError('build.gradle.kts: signingConfig debug gak ketemu');
  g = g.replaceFirst(debugSign, 'signingConfig = signingConfigs.getByName("novaRelease")');
  f.writeAsStringSync(g);
  stdout.writeln('+ kunci tanda tangan permanen');
}

void main(List<String> args) {
  if (args.contains('--sign')) {
    patchSigning();
    return;
  }
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
  patchWidget(manifest.path);
  // Layanan Aksesibilitas (mode presisi pulau) udah dibuang: bikin APK diblok Play
  // Protect. Sisa dari build lama dibersihin.
  unpatchAccessibility(manifest.path);

  stdout.writeln('Beres. Lanjut: flutter pub get');
}
