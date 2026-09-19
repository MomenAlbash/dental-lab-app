import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';

sealed class NotificationsState {
  const NotificationsState();
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(
    this.notifications, {
    this.page = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<NotificationModel> notifications;

  /// The last page fetched.
  final int page;

  /// Whether the server said there is more. **False when the list came from
  /// the unpaged endpoint or the offline cache** — those have no next page, so
  /// offering one would spin forever at the bottom.
  final bool hasMore;

  final bool isLoadingMore;

  NotificationsLoaded copyWith({
    List<NotificationModel>? notifications,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) => NotificationsLoaded(
    notifications ?? this.notifications,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

class NotificationsError extends NotificationsState {
  const NotificationsError(this.message);
  final String message;
}

/// Emitted after an optimistic read-state update is rolled back — a toast
/// only, never something the list rebuilds on directly.
class NotificationsMarkError extends NotificationsState {
  const NotificationsMarkError(this.message);
  final String message;
}
