import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';
import 'package:dental_lab_app/features/notifications/logic/notifications_cubit.dart';
import 'package:dental_lab_app/features/notifications/ui/widgets/notification_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The notifications list section with pull-to-refresh.
class NotificationsListView extends StatelessWidget {
  const NotificationsListView({
    super.key,
    required this.notifications,
    this.scrollController,
  });

  final List<NotificationModel> notifications;

  /// Owned by the page, which watches it to collapse the "mark all read"
  /// action.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveCollection<NotificationModel>(
      items: notifications,
      // The wider bottom margin on the card itself (see
      // NotificationListItemWidget) needs the extra room here too, or the
      // tablet grid — which sizes rows off this value — clips it back off.
      cardHeight: 116,
      scrollController: scrollController,
      onRefresh: () => context.read<NotificationsCubit>().getNotifications(),
      itemBuilder: (context, notification, _) => NotificationListItemWidget(
        notification: notification,
        onTap: () => _onTap(context, notification),
      ),
    );
  }

  void _onTap(BuildContext context, NotificationModel notification) {
    context.read<NotificationsCubit>().markAsRead(notification.id);

    final caseId = notification.relatedEntityId;
    // Only Case has a detail screen in this app today — the rest still mark
    // as read, they just have nowhere concrete to send the user yet.
    if (notification.type == NotificationType.caseType && caseId != null) {
      context.push(Routes.caseDetailScreen, extra: caseId);
    }
  }
}
