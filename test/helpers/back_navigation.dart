import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates the Android system back gesture — the real path: the platform
/// sends `popRoute`, which the framework turns into `Navigator.maybePop`.
///
/// This is what exercises `PopScope`; a plain `Navigator.pop` would bypass it.
Future<void> systemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}
