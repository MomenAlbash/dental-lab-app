import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_page_model.dart';
import 'package:dio/dio.dart';

class NotificationsRepo {
  final ApiService _apiService;
  NotificationsRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<NotificationModel>>> getNotifications({
    bool unreadOnly = false,
  }) async {
    try {
      final notifications = await _apiService.getNotifications(
        unreadOnly: unreadOnly,
        token: _token,
      );

      log('Fetched ${notifications.length} notifications');
      return right(notifications);
    } on DioException catch (e) {
      log('DioException while fetching notifications: ${e.message}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedNotificationsList,
        fromJson: NotificationModel.fromJson,
        onFailure: () => ServerFailure.fromDioException(e),
      );
    } catch (e) {
      log('General Exception while fetching notifications: $e');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedNotificationsList,
        fromJson: NotificationModel.fromJson,
        onFailure: () => ServerFailure.fromException(e),
      );
    }
  }

  /// One page of notifications.
  ///
  /// No cache fallback, unlike [getNotifications]: the offline cache holds one
  /// flat list, and serving it as "page 3" would silently restart the user at
  /// the top of a list they had scrolled through.
  Future<Either<Failure, NotificationPageModel>> getPage({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final result = await _apiService.getNotificationsPaged(
        unreadOnly: unreadOnly,
        page: page,
        pageSize: pageSize,
        token: _token,
      );

      log('Fetched notifications page $page (${result.items.length} items)');
      return right(result);
    } on DioException catch (e) {
      log('DioException while fetching a notifications page: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching a notifications page: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Pushes a notification to many people at once.
  ///
  /// **No undo.** Sent is sent — which is why the form that calls this
  /// confirms first.
  Future<Either<Failure, void>> broadcast(
    BroadcastNotificationRequestModel body,
  ) async {
    try {
      await _apiService.broadcastNotification(body: body, token: _token);

      log('Broadcast sent to ${body.audience.name}');
      return right(null);
    } on DioException catch (e) {
      log('DioException while broadcasting: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while broadcasting: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> markAsRead(String id) async {
    try {
      await _apiService.markNotificationRead(id: id, token: _token);

      log('Marked notification as read: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while marking notification as read: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while marking notification as read: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Best-effort — a failure here must never surface to the user or block
  /// login, since the server side of this endpoint is not confirmed working
  /// yet. Callers only need the log line.
  Future<void> registerDeviceToken({
    required String deviceToken,
    required DevicePlatform platform,
  }) async {
    try {
      await _apiService.registerDeviceToken(
        deviceToken: deviceToken,
        platform: platform,
        token: _token,
      );
      log('Registered device token for push');
    } catch (e) {
      log(
        'Device token registration failed (expected until the server side '
        'is fixed): $e',
      );
    }
  }

  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsRead(token: _token);

      log('Marked all notifications as read');
      return right(null);
    } on DioException catch (e) {
      log('DioException while marking all notifications as read: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while marking all notifications as read: $e');
      return left(ServerFailure.fromException(e));
    }
  }
}
