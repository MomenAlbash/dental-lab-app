import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// A case row — matches the doctor/employee/role card: an accent rail
/// coloured by priority, an icon avatar, then patient/case-number/badges.
class CaseListItemWidget extends StatelessWidget {
  const CaseListItemWidget({
    super.key,
    required this.caseNumber,
    required this.patientName,
    required this.doctorName,
    this.laboratoryName = '',
    this.cityName = '',
    this.productionSummary = '',
    required this.stageName,
    required this.stageColor,
    required this.isLate,
    required this.priorityLabel,
    required this.priorityColor,
    required this.onTap,
    this.onShowBreakdown,
    this.onDelete,
  });

  final String caseNumber;
  final String patientName;
  final String doctorName;

  /// The laboratory and city this case belongs to. Empty hides the line —
  /// on a single-lab, single-city view they would repeat on every row and
  /// say nothing.
  final String laboratoryName;
  final String cityName;

  /// One representative restoration's stage while the case is mid-production,
  /// and how many others are elsewhere — e.g. "زيركون: طحن (+2 مراحل أخرى)".
  /// Empty hides the line: a list row only ever gets one restoration's stage
  /// summarised, never a full per-restoration breakdown, so this is a
  /// glimpse, not the whole picture.
  final String productionSummary;

  /// Where the case is in the lab's workflow. Empty when it has no stage — no
  /// badge is drawn rather than a made-up one.
  final String stageName;

  /// Resolved from the stage's own `badgeVariant` token.
  final Color stageColor;

  /// Past its expected completion. Shown as its own chip, not by colour alone.
  final bool isLate;

  /// The case's priority as text — empty when it has none, in which case no
  /// badge is drawn. Priorities are lab-defined, so the label comes from the
  /// case itself rather than from an enum.
  final String priorityLabel;

  /// Resolved by the caller from the priority's `badgeVariant`, since the
  /// case rows themselves only carry the priority's id and name.
  final Color priorityColor;
  final VoidCallback onTap;

  /// Opens the per-restoration breakdown — where the pieces this row only
  /// counts have actually reached.
  ///
  /// Null hides the button, mirroring [onDelete]'s contract so both trailing
  /// actions behave alike. It is null for a case with no restorations, where
  /// there is nothing to break down, and on the dashboard, which shows this
  /// row as a glance rather than a working list.
  final VoidCallback? onShowBreakdown;

  /// Null hides the delete button entirely — the dashboard shows the same row
  /// as a read-only summary, where a destructive action next to a glance-level
  /// list is a mis-tap waiting to happen.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final railColor = priorityColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: glass.brandGradient,
                              ),
                              child: const Icon(
                                Icons.folder_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      if (doctorName.isNotEmpty) ...[
                                        Flexible(
                                          child: Text(
                                            'د. $doctorName',
                                            style: AppTextStyles
                                                .font12RegularHint
                                                .copyWith(
                                                  color: glass.onGlassMuted,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            '_',
                                            style: AppTextStyles
                                                .font12RegularHint
                                                .copyWith(
                                                  color: glass.onGlassMuted,
                                                ),
                                          ),
                                        ),
                                      ],
                                      Flexible(
                                        child: Text(
                                          patientName.isEmpty
                                              ? '—'
                                              : patientName,
                                          style: AppTextStyles.font14MediumText
                                              .copyWith(
                                                color: glass.onGlassMuted,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (priorityLabel.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        _Badge(
                                          label: priorityLabel,
                                          color: railColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  // Lab and city on their own line, and only
                                  // when the row carried them: browsing one
                                  // lab prints the same name on every card,
                                  // which is noise rather than information.
                                  if (laboratoryName.isNotEmpty ||
                                      cityName.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.business_outlined,
                                          size: 12,
                                          color: glass.onGlassMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            [laboratoryName, cityName]
                                                .where((v) => v.isNotEmpty)
                                                .join(' · '),
                                            style: AppTextStyles
                                                .font12RegularHint
                                                .copyWith(
                                                  color: glass.onGlassMuted,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                  ],
                                  Text(
                                    caseNumber.isEmpty
                                        ? 'بدون رقم'
                                        : 'رقم: $caseNumber',
                                    style: AppTextStyles.font12RegularHint
                                        .copyWith(color: glass.onGlassMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      // Tinted by the stage's own token rather
                                      // than a fixed green: the lab picks what
                                      // each stage means.
                                      if (stageName.isNotEmpty)
                                        _Badge(
                                          label: stageName,
                                          color: stageColor,
                                        ),
                                      if (isLate) ...[
                                        const SizedBox(width: 6),
                                        _Badge(
                                          label: 'متأخرة',
                                          color: glass.error,
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (productionSummary.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .precision_manufacturing_outlined,
                                          size: 12,
                                          color: glass.onGlassMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            productionSummary,
                                            style: AppTextStyles
                                                .font12RegularHint
                                                .copyWith(
                                                  color: glass.onGlassMuted,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Inboard of delete, never outboard: the app runs
                            // RTL, so delete keeps the outer edge and the
                            // tap position of the one button here you must
                            // never hit by accident does not move.
                            if (onShowBreakdown != null)
                              IconButton(
                                tooltip: 'تفاصيل التعويضات',
                                onPressed: onShowBreakdown,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                // Tightened well below IconButton's default so
                                // the second action costs the content column
                                // 32dp rather than 40 — it is competing with
                                // the patient's name on a 360dp phone.
                                constraints: const BoxConstraints.tightFor(
                                  width: 32,
                                  height: 32,
                                ),
                                icon: Icon(
                                  Icons.account_tree_outlined,
                                  size: 18,
                                  // Muted, not accented: a second saturated
                                  // icon beside the red one would make the row
                                  // read as a toolbar.
                                  color: glass.onGlassMuted,
                                ),
                              ),
                            if (onDelete != null)
                              IconButton(
                                tooltip: 'حذف',
                                onPressed: onDelete,
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: glass.error,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}
