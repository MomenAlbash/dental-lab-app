import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Logs a request or response body — in debug builds only.
///
/// Bodies carry patients' names and phone numbers, doctors' balances and, on
/// login, the token itself. A developer needs them while building; nobody
/// needs them in a profile or release build, where anything logged can be
/// read off a connected device.
void logBody(String label, Object? body) {
  if (kDebugMode) developer.log('$label: $body');
}

/// A body to put inside a log line: itself in a debug build, `<hidden>` in
/// any other — for the many `log('X response data: …')` lines that name
/// what answered while keeping the answer out of release logs.
Object? logSafe(Object? body) => kDebugMode ? body : '<hidden>';
