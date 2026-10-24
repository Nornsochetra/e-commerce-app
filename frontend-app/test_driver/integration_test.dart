import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves screenshots taken by integration_test/review_screenshots_test.dart into build/screenshots/.
/// Run: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/review_screenshots_test.dart -d "iPhone 16"
Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final file = File('build/screenshots/$name.png')..createSync(recursive: true);
        file.writeAsBytesSync(bytes);
        return true;
      },
    );
