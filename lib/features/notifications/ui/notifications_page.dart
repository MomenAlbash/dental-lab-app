import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';
import 'package:dental_lab_app/features/notifications/logic/notifications_cubit.dart';
import 'package:dental_lab_app/features/notifications/logic/notifications_state.dart';
import 'package:dental_lab_app/features/notifications/ui/widgets/notifications_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The notifications tab: an in-app inbox fed by `GET /Notifications`.
///
/// This is not push — the server's device-token registration is not working
/// yet, so nothing arrives while the app is closed or backgrounded. What is
/// here is what has already landed, fetched when the tab opens.
class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotificationsCubit>()..getNotifications(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  final _scrollController = ScrollController();

  /// Last successfully loaded notifications, kept so a refresh shows the
  /// existing rows instead of replacing them with the loading skeleton.
  List<NotificationModel>? _lastNotifications;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Asks for the next page before the user reaches the bottom, so a long
  /// list does not stutter at every page boundary. The cubit ignores the call
  /// when there is nothing more — including when the list came from the
  /// unpaged endpoint or the offline cache, which have no next page.
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      context.read<NotificationsCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.homeScreen),
      appBar: GlassAppBar(
        title: Text(
          'الإشعارات',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
        actions: [
          if (getIt<SessionCubit>().state.canEdit(PermissionName.users))
            IconButton(
              tooltip: 'إرسال إشعار',
              onPressed: () => context.push(Routes.broadcastScreen),
              icon: const Icon(Icons.campaign_outlined),
            ),
          BlocBuilder<NotificationsCubit, NotificationsState>(
            buildWhen: (_, current) => current is NotificationsLoaded,
            builder: (context, state) {
              final hasUnread =
                  state is NotificationsLoaded &&
                  state.notifications.any((n) => !n.isRead);
              return IconButton(
                tooltip: 'تمييز الكل كمقروء',
                onPressed: hasUnread
                    ? () => context.read<NotificationsCubit>().markAllAsRead()
                    : null,
                icon: Icon(
                  Icons.done_all_rounded,
                  color: hasUnread ? glass.onGlass : glass.onGlassMuted,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<NotificationsCubit, NotificationsState>(
          listener: (context, state) {
            if (state is NotificationsMarkError) {
              showToast(message: state.message, state: ToastState.error);
            }
          },
          buildWhen: (_, current) => current is! NotificationsMarkError,
          builder: (context, state) {
            if (state is NotificationsLoaded) {
              _lastNotifications = state.notifications;
            }

            final notifications = switch (state) {
              NotificationsLoaded(:final notifications) => notifications,
              NotificationsLoading() => _lastNotifications,
              _ => null,
            };

            return AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: switch ((state, notifications)) {
                (_, final List<NotificationModel> loaded) when loaded.isEmpty =>
                  const _EmptyState(key: ValueKey('notifications-empty')),
                (_, final List<NotificationModel> loaded) =>
                  NotificationsListView(
                    key: const ValueKey('notifications-loaded'),
                    notifications: loaded,
                    scrollController: _scrollController,
                  ),
                (NotificationsError(:final message), null) => Center(
                  key: const ValueKey('notifications-error'),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.font14RegularSecondary.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  ),
                ),
                _ => const Padding(
                  key: ValueKey('notifications-loading'),
                  padding: EdgeInsets.only(top: 24),
                  child: GlassListSkeleton(),
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: glass.surfaceGradient,
                    border: Border.all(color: glass.strokeColor),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد إشعارات بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: AppMotion.base,
          curve: AppMotion.enter,
        );
  }
}
