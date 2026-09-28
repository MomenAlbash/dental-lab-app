import 'dart:developer';

import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_page_model.dart';

/// The `notifications` endpoints — split out of
/// [ApiService], reached through the same instance.
extension NotificationsApi on ApiService {
  // ---------------------------------------------------------- notifications ---

  /// `POST /Notifications/device-token`.
  ///
  /// The server side of this is not confirmed working yet — callers must
  /// treat a failure here as non-fatal (log it, do not surface it to the
  /// user), since push simply won't arrive until it is, but nothing else in
  /// the app depends on it.
  Future<void> registerDeviceToken({
    required String deviceToken,
    required DevicePlatform platform,
    String? token,
  }) async {
    log('Registering device token for push (${platform.name})');

    await Api().post(
      url: 'Notifications/device-token',
      body: {'token': deviceToken, 'platform': platform.value},
      token: token,
    );
  }

  /// `GET /Notifications/paged`
  ///
  /// The endpoint declares no response schema, so the answer is accepted in
  /// either plausible shape — an envelope or a bare list. See
  /// [NotificationPageModel] for why that is a reading rather than defensive
  /// padding.
  Future<NotificationPageModel> getNotificationsPaged({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 30,
    String? token,
  }) async {
    log('Fetching notifications page $page');

    final data = await Api().get(
      url:
          'Notifications/paged?UnreadOnly=$unreadOnly'
          '&Page=$page&PageSize=$pageSize',
      token: token,
    );

    if (data is List) return NotificationPageModel.fromList(data);
    return NotificationPageModel.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /Notifications/broadcast` — a push to many people at once.
  ///
  /// The one write in this app with no undo: sent is sent.
  Future<void> broadcastNotification({
    required BroadcastNotificationRequestModel body,
    String? token,
  }) async {
    log('Broadcasting a notification to ${body.audience.name}');

    await Api().post(
      url: 'Notifications/broadcast',
      body: body.toJson(),
      token: token,
    );
  }

  /// `GET /Notifications`
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    String? token,
  }) async {
    log('Fetching notifications (unreadOnly: $unreadOnly)');

    final data = await Api().get(
      url: 'Notifications?unreadOnly=$unreadOnly',
      token: token,
    );

    if (!unreadOnly) {
      await CacheHelper.saveJson(
        key: CacheKeys.cachedNotificationsList,
        value: data,
      );
    }

    return decodeJsonList(data, NotificationModel.fromJson);
  }

  /// `POST /Notifications/{id}/read`
  Future<void> markNotificationRead({required String id, String? token}) async {
    log('Marking notification as read: $id');

    await Api().post(
      url: 'Notifications/$id/read',
      body: const <String, dynamic>{},
      token: token,
    );
  }

  /// `POST /Notifications/read-all`
  Future<void> markAllNotificationsRead({String? token}) async {
    log('Marking all notifications as read');

    await Api().post(
      url: 'Notifications/read-all',
      body: const <String, dynamic>{},
      token: token,
    );
  }


}
