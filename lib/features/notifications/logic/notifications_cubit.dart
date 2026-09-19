import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';
import 'package:dental_lab_app/features/notifications/data/repos/notifications_repo.dart';
import 'package:dental_lab_app/features/notifications/logic/notifications_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repo) : super(const NotificationsInitial());

  final NotificationsRepo _repo;

  /// Loads the first page.
  ///
  /// The paged endpoint is tried first and the flat one is the fallback,
  /// rather than the other way round: `Notifications/paged` declares no
  /// response schema, so if it answers in a shape this client cannot read, the
  /// screen degrades to exactly the behaviour it had before paging existed —
  /// one list, no infinite scroll — instead of showing an error.
  ///
  /// The flat path also keeps the offline cache fallback, which the paged one
  /// deliberately has not: serving a cached flat list as "page 3" would
  /// silently restart the user at the top of a list they had scrolled.
  Future<void> getNotifications() async {
    emit(const NotificationsLoading());

    final paged = await _repo.getPage();
    if (isClosed) return;

    final gotPage = paged.fold((_) => false, (page) {
      emit(
        NotificationsLoaded(
          page.items,
          page: page.page,
          hasMore: page.hasMore,
        ),
      );
      return true;
    });
    if (gotPage) return;

    final result = await _repo.getNotifications();
    if (isClosed) return;

    result.fold(
      (failure) => emit(NotificationsError(failure.errorMessage)),
      // No `hasMore`: this list has no next page.
      (notifications) => emit(NotificationsLoaded(notifications)),
    );
  }

  /// Appends the next page.
  Future<void> loadMore() async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final result = await _repo.getPage(page: current.page + 1);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(NotificationsMarkError(failure.errorMessage));
        emit(current.copyWith(isLoadingMore: false));
      },
      (next) => emit(
        current.copyWith(
          notifications: [...current.notifications, ...next.items],
          page: next.page,
          hasMore: next.hasMore,
          isLoadingMore: false,
        ),
      ),
    );
  }

  /// Marks one notification as read, optimistically — the tap that opens it
  /// should not wait on a round trip to stop showing as unread. Rolled back
  /// (with a toast, via [NotificationsMarkError]) if the server call fails.
  Future<void> markAsRead(String id) async {
    final state = this.state;
    if (state is! NotificationsLoaded) return;

    final target = _find(state.notifications, id);
    if (target == null || target.isRead) return;

    emit(NotificationsLoaded(_replace(state.notifications, id, isRead: true)));

    final result = await _repo.markAsRead(id);

    result.fold((failure) {
      emit(NotificationsLoaded(state.notifications));
      emit(NotificationsMarkError(failure.errorMessage));
    }, (_) {});
  }

  Future<void> markAllAsRead() async {
    final state = this.state;
    if (state is! NotificationsLoaded) return;

    final previous = state.notifications;
    final hasUnread = previous.any((n) => !n.isRead);
    if (!hasUnread) return;

    emit(
      NotificationsLoaded([for (final n in previous) n.copyWith(isRead: true)]),
    );

    final result = await _repo.markAllAsRead();

    result.fold((failure) {
      emit(NotificationsLoaded(previous));
      emit(NotificationsMarkError(failure.errorMessage));
    }, (_) {});
  }

  NotificationModel? _find(List<NotificationModel> notifications, String id) {
    for (final n in notifications) {
      if (n.id == id) return n;
    }
    return null;
  }

  List<NotificationModel> _replace(
    List<NotificationModel> notifications,
    String id, {
    required bool isRead,
  }) {
    return [
      for (final n in notifications)
        if (n.id == id) n.copyWith(isRead: isRead) else n,
    ];
  }
}
