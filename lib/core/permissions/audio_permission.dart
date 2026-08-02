import 'package:record/record.dart';

/// Single entry point for microphone permission — requests (or checks) it
/// through the `record` package rather than a platform API called directly
/// from UI/logic. Returns true once the mic is usable for recording.
Future<bool> ensureMicrophonePermission() {
  return AudioRecorder().hasPermission();
}
