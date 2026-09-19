import 'dart:developer';

import 'package:dental_lab_app/core/permissions/notification_permission.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';
import 'package:dental_lab_app/features/notifications/data/repos/notifications_repo.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'إشعارات المخبر',
  description: 'إشعارات الحالات والمواعيد والتحديثات المهمة.',
  importance: Importance.high,
);

final _localNotifications = FlutterLocalNotificationsPlugin();

/// Runs in its own isolate when a push arrives while the app is backgrounded
/// or terminated. Must stay top-level and `@pragma`-marked (the plugin looks
/// it up by reference at the engine level, not through this file's normal
/// import graph), and re-initializes Firebase itself since a background
/// isolate does not share the main isolate's state.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // A `notification` payload is already shown by the OS at this point —
  // only a data-only message needs manual display.
  if (message.notification == null) {
    await _showLocalNotification(message);
  }
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final title = message.notification?.title ?? message.data['title'];
  final body = message.notification?.body ?? message.data['body'];
  if (title == null && body == null) return;

  await _localNotifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_androidChannel);

  await _localNotifications.show(
    id: message.hashCode,
    title: title as String?,
    body: body as String?,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );
}

/// Owns the app's push-notification plumbing: permission, the FCM device
/// token, and turning a foreground message into something the user actually
/// sees — neither platform auto-shows a system notification for a message
/// that arrives while the app is in the foreground.
class PushNotificationService {
  PushNotificationService(this._repo);

  final NotificationsRepo _repo;

  /// Bumped whenever a push is tapped — cold-start or warm. Carries no
  /// payload: the API does not document a field linking a notification back
  /// to a case yet, so the shell can only open the notifications tab, not
  /// deep-link to the specific case. Revisit once that field is confirmed.
  final ValueNotifier<int> notificationTapped = ValueNotifier(0);

  bool _initialized = false;

  /// Call once at startup, before the first frame. Safe to call more than
  /// once — later calls are a no-op.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (_) => notificationTapped.value++,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (_) => notificationTapped.value++,
    );

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) notificationTapped.value++;
  }

  /// Call after a successful login, and defensively at startup for a user
  /// already signed in from a previous session. Never throws — push is a
  /// nice-to-have that must not block or fail a login.
  Future<void> requestPermissionAndRegister() async {
    try {
      final granted = await ensureNotificationPermission();
      if (!granted) return;

      final token = await FirebaseMessaging.instance.getToken();
      // Printed so it can be pasted into Firebase Console → Cloud Messaging
      // → "Send test message" while the server side isn't storing it yet.
      log('FCM device token: $token');
      if (token != null) {
        await _repo.registerDeviceToken(
          deviceToken: token,
          platform: _platform,
        );
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((refreshed) {
        _repo.registerDeviceToken(deviceToken: refreshed, platform: _platform);
      });
    } catch (e) {
      log('Push permission/registration failed: $e');
    }
  }

  DevicePlatform get _platform => defaultTargetPlatform == TargetPlatform.iOS
      ? DevicePlatform.ios
      : DevicePlatform.android;
}
