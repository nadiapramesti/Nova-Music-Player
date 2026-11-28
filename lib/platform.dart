import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Nova versi laptop (Windows; Linux/macOS ikut kebawa tapi belum dites).
bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// Nova versi HP (semua fitur native Android: MediaStore, notifikasi, widget, dll).
bool get isAndroid => !kIsWeb && Platform.isAndroid;
