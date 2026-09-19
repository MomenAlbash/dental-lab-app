import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/badge_variant.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:flutter/material.dart';

/// One session on the dispatch board.
class ScannerSessionListItem extends StatelessWidget {
  const ScannerSessionListItem({
    super.key,
    required this.session,
    required this.onAssign,
    required this.onReview,
    required this.onMessages,
  });

  final ScannerSessionModel session;
  final VoidCallback onAssign;

  /// Null hides the review action — only a session with a scan to look at can
  /// be reviewed.
  final VoidCallback? onReview;

  /// Opens the thread with the doctor about this appointment.
  final VoidCallback onMessages;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final statusColor = badgeVariantColor(
      context,
      session.status?.badgeVariant,
    );

    // The rail is the alarm: a session nobody is coming to reads red down its
    // whole edge, so the queue can be triaged without reading a word.
    final railColor = session.needsAttention ? glass.error : statusColor;

    return Container(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: railColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(session: session),
                        const SizedBox(height: 6),
                        _Meta(session: session),
                        const SizedBox(height: AppSpacing.sm),
                        _Badges(session: session, statusColor: statusColor),
                        const SizedBox(height: AppSpacing.sm),
                        _Actions(
                          session: session,
                          onAssign: onAssign,
                          onReview: onReview,
                          onMessages: onMessages,
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session});

  final ScannerSessionModel session;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Row(
      children: [
        Expanded(
          child: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font16MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
        ),
        if (session.scheduledAt != null)
          Text(
            _formatDateTime(session.scheduledAt!),
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.session});

  final ScannerSessionModel session;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final parts = [
      session.doctorName,
      session.clinicName,
      session.zoneName,
    ].whereType<String>().where((s) => s.trim().isNotEmpty);

    return Text(
      parts.isEmpty ? '—' : parts.join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.font12RegularHint.copyWith(
        color: glass.onGlassMuted,
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.session, required this.statusColor});

  final ScannerSessionModel session;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final response = session.representativeResponse;
    final review = session.reviewStatus;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (session.status != null)
          _Chip(label: session.status!.label, color: statusColor),

        // Who has it now. Unassigned is stated outright rather than left as an
        // absence the reader has to notice.
        if (session.assignedRepresentativeName?.isNotEmpty ?? false)
          _Chip(
            label: session.assignedRepresentativeName!,
            color: glass.info,
            icon: Icons.person_outline,
          )
        else if (session.status?.isOpen ?? false)
          _Chip(
            label: 'بدون مندوب',
            color: glass.error,
            icon: Icons.person_off_outlined,
          ),

        if (response != null)
          _Chip(
            label: response.label,
            color: badgeVariantColor(context, response.badgeVariant),
          ),

        if (review != null)
          _Chip(
            label: review.label,
            color: badgeVariantColor(context, review.badgeVariant),
          ),

        // A third redo is a conversation, not a queue item — so the count is
        // shown rather than just the status.
        if (session.redoCount > 0)
          _Chip(label: 'إعادة ×${session.redoCount}', color: glass.warning),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.session,
    required this.onAssign,
    required this.onReview,
    required this.onMessages,
  });

  final ScannerSessionModel session;
  final VoidCallback onAssign;
  final VoidCallback? onReview;
  final VoidCallback onMessages;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        TextButton.icon(
          onPressed: onAssign,
          icon: const Icon(Icons.person_search_outlined, size: 16),
          label: Text(
            session.assignedRepresentativeId == null
                ? 'إسناد مندوب'
                : 'تغيير المندوب',
          ),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
        if (onReview != null)
          TextButton.icon(
            onPressed: onReview,
            icon: const Icon(Icons.fact_check_outlined, size: 16),
            label: const Text('مراجعة المسح'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        // Always offered, never gated on the session having messages: the
        // point of the thread is usually to start one — "the scanner is free
        // an hour earlier" is said before there is anything to say it about.
        TextButton.icon(
          onPressed: onMessages,
          icon: const Icon(Icons.chat_bubble_outline, size: 16),
          label: const Text('المراسلة'),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTextStyles.font12RegularHint.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// `dd/MM · HH:mm`, kept LTR so the digits do not reorder inside RTL text.
String _formatDateTime(DateTime at) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '\u202A${two(at.day)}/${two(at.month)} · ${two(at.hour)}:'
      '${two(at.minute)}\u202C';
}
