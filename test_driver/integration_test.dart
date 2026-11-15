import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Simpan tiap screenshot dari integration_test/screenshots_test.dart ke screenshots/.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('screenshots/$name.png');
      file.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
      return true;
    },
  );
}
