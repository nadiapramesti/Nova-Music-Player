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

  stdout.writeln('Beres. Lanjut: flutter pub get');
}
