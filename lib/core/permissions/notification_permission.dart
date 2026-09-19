import 'package:firebase_messaging/firebase_messaging.dart';

/// Single entry point for the notification permission — requests it through
/// `firebase_messaging` (which also handles Android 13+'s runtime
/// `POST_NOTIFICATIONS` prompt) rather than a platform API called directly
/// from UI/logic.
///
/// `provisional` (iOS-only "quiet" delivery) counts as granted: it still
/// lets a push arrive, just without an alert until the user engages with one.
Future<bool> ensureNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission();
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}
