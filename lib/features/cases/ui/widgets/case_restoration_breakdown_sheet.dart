import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_breakdown_group.dart';
import 'package:flutter/material.dart';

/// Where a case's restorations actually are, by type and stage.
///
/// The row carries one representative stage and a count of "others elsewhere";
/// this is the elsewhere. **It opens without a request** — every figure here
/// already arrived with the cases list, so there is no loading state to draw.
///
/// Grouped, not per-piece: this answers "how many of what, and where". The
/// full route of one restoration, with its own number and every step it has
/// taken, is the case detail's "تقدم الحالة" tab.
Future<void> showCaseRestorationBreakdownSheet(
  BuildContext context, {
  required CaseListItemModel caseItem,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => _CaseRestorationBreakdownSheet(caseItem: caseItem),
  );
}

class _CaseRestorationBreakdownSheet extends StatelessWidget {
  const _CaseRestorationBreakdownSheet({required this.caseItem});

  final CaseListItemModel caseItem;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final groups = caseItem.orderedRestorationBreakdown;

    final subtitle = [
      if (caseItem.patientName?.trim().isNotEmpty ?? false)
        caseItem.patientName!.trim(),
      if (caseItem.caseNumber?.trim().isNotEmpty ?? false)
        'رقم: ${caseItem.caseNumber!.trim()}',
      // The server's own total, never a sum of the groups below: if a
      // projection ever excluded a piece from the breakdown, summing here
      // would publish a number the server never said.
      '${caseItem.restorationsCount} تعويض',
    ].join(' · ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تفاصيل التعويضات',
            style: AppTextStyles.font18MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // The button that opens this sheet is hidden when there is nothing
          // to show, so this branch is for any other caller — a bare drag
          // handle over nothing reads as a failure to load.
          if (groups.isEmpty)
            Text(
              'لا توجد تعويضات على هذا الطلب',
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            )
          else
            for (final group in groups) _GroupRow(group: group),

          if (groups.any((group) => !group.hasStarted)) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              // Said plainly so "لم تبدأ" is not read as a fault: the piece
              // joins its route once its plan is cut, which can be after the
              // case itself has moved on.
              'التعويض يبدأ مساره بعد اعتماد خطّته',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group});

  final CaseRestorationBreakdownGroup group;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;
    final typeLabel = group.restorationTypeLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          // The count sits in its own box rather than being interpolated into
          // the name. "زيركون ×2" as one string puts the multiplier and the
          // Latin digits under bidi reordering inside an RTL paragraph, which
          // is how the same row renders differently on two devices. A box
          // cannot be reordered relative to the text beside it.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '×${group.count}',
              style: AppTextStyles.font12RegularHint.copyWith(color: accent),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Text(
              typeLabel.isEmpty ? '—' : typeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font14MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          Text(
            group.hasStarted ? group.stageLabel : 'لم تبدأ',
            style: AppTextStyles.font12RegularHint.copyWith(
              // Muted rather than badged: a group that has not started is an
              // absence, and dressing it as a status would make it compete
              // with the real stages beside it.
              color: group.hasStarted ? glass.onGlass : glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }
}
