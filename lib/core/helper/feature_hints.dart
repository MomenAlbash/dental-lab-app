import 'package:dental_lab_app/core/helper/local/cached_helper.dart';

/// One-time introductions to features that are easy to miss. Each is shown
/// once per device and remembered after — a hint that keeps coming back is
/// noise, not help.
enum FeatureHint {
  /// The barcode scanner on the home screen.
  barcodeScanner('hint_seen_barcode_scanner');

  const FeatureHint(this._key);

  final String _key;

  bool get isSeen => CacheHelper.getData(key: _key) == true;

  Future<void> markSeen() => CacheHelper.saveData(key: _key, value: true);
}
