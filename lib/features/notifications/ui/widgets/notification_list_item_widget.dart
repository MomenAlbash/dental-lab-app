import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';
import 'package:flutter/material.dart';

/// A notification row — an accent rail marks it unread, muted once read.
class NotificationListItemWidget extends StatelessWidget {
  const NotificationListItemWidget({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  String? get _timeAgo {
    final createdAt = notification.createdAt;
    if (createdAt == null) return null;

    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final isUnread = !notification.isRead;
    final railColor = isUnread ? glass.primaryDark : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: railColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isUnread ? glass.brandGradient : null,
                                color: isUnread ? null : glass.strokeColor,
                              ),
                              child: Icon(
                                Icons.notifications_rounded,
                                color: isUnread
                                    ? Colors.white
                                    : glass.onGlassMuted,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    notification.title?.trim().isNotEmpty ==
                                            true
                                        ? notification.title!
                                        : 'إشعار',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.font16MediumText
                                        .copyWith(
                                          color: isUnread
                                              ? glass.onGlass
                                              : glass.onGlassMuted,
                                        ),
                                  ),
                                  if (notification.message?.trim().isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      notification.message!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles
                                          .font14RegularSecondary
                                          .copyWith(color: glass.onGlassMuted),
                                    ),
                                  ],
                                  if (_timeAgo != null) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      _timeAgo!,
                                      style: AppTextStyles.font12RegularHint
                                          .copyWith(color: glass.onGlassMuted),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
