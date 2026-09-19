import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Single entry point for the label printer's Bluetooth access — requested
/// (or checked) here rather than a platform API called directly from the
/// printing UI.
///
/// Android needs `bluetoothScan` + `bluetoothConnect` on API 31+, and falls
/// back to `location` on older releases where BLE scanning is resolved
/// through it instead. iOS only ever asks for `bluetooth`.
Future<bool> ensureBluetoothPermission() async {
  if (!Platform.isAndroid && !Platform.isIOS) return true;

  final statuses = await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
    Permission.bluetooth,
  ].request();

  if (Platform.isIOS) {
    return statuses[Permission.bluetooth]?.isGranted ?? false;
  }

  final scan = statuses[Permission.bluetoothScan];
  final connect = statuses[Permission.bluetoothConnect];
  // Pre-Android 12 declares neither runtime permission, so `permission_
  // handler` reports them as permanently denied rather than granted — fall
  // back to whether location was granted instead of trusting that reading.
  final legacyOk = statuses[Permission.location]?.isGranted ?? false;

  return (scan?.isGranted ?? false) && (connect?.isGranted ?? false) ||
      legacyOk;
}
