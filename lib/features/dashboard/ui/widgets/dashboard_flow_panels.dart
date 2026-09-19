import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_breakdown_models.dart';
import 'package:flutter/material.dart';

/// The lifecycle funnel: every case is in exactly one phase, so the column
/// adds up to the laboratory's total.
///
/// Each row carries its overdue count beside the total, because "٤٠ قيد
/// الإنتاج" and "٤٠ قيد الإنتاج، ١٢ منها متأخرة" call for different actions —
/// and the first is all a bare bar chart would have said.
class DashboardPhaseFunnel extends StatelessWidget {
  const DashboardPhaseFunnel({super.key, required this.phases});

  final List<CasePhaseCountModel> phases;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final total = phases.fold<int>(0, (sum, phase) => sum + phase.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final phase in phases)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        phase.label,
                        style: AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                    ),
                    if (phase.overdueCount > 0)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: AppSpacing.sm,
                        ),
                        child: Text(
                          '${phase.overdueCount} متأخرة',
                          style: AppTextStyles.font12RegularHint.copyWith(
                            color: glass.error,
                          ),
                        ),
                      ),
                    Text(
                      '${phase.count}',
                      style: AppTextStyles.font14MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    // Against the total rather than the largest phase: this is
                    // a funnel, and each row's share of the whole is the point.
                    value: total == 0 ? 0 : phase.count / total,
                    minHeight: 6,
                    backgroundColor: glass.fillColor,
                  ),
                ),
              ],
            ),
          ),
        if (total > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'المجموع $total حالة',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Arrivals against deliveries, day by day.
///
/// Two bars per day rather than one net figure: a net of zero can mean a quiet
/// day or a frantic one, and telling those apart is the whole question a
/// backlog chart exists to answer.
class DashboardCaseFlowChart extends StatelessWidget {
  const DashboardCaseFlowChart({super.key, required this.points});

  final List<CaseFlowPointModel> points;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    // At least one, so a period with no movement at all divides safely.
    final peak = points.fold<int>(1, (max, point) {
      final dayPeak = point.created > point.delivered
          ? point.created
          : point.delivered;
      return dayPeak > max ? dayPeak : max;
    });

    final createdTotal = points.fold<int>(0, (sum, p) => sum + p.created);
    final deliveredTotal = points.fold<int>(0, (sum, p) => sum + p.delivered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _FlowLegend(color: accent, label: 'وارد $createdTotal'),
            const SizedBox(width: AppSpacing.md),
            _FlowLegend(color: glass.success, label: 'مسلَّم $deliveredTotal'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in points)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                height: 96 * (point.created / peak),
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 1),
                            Expanded(
                              child: Container(
                                height: 96 * (point.delivered / peak),
                                color: glass.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          point.date == null ? '' : '${point.date!.day}',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: AppTextStyles.font12RegularHint.copyWith(
                            color: glass.onGlassMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowLegend extends StatelessWidget {
  const _FlowLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.font12RegularHint.copyWith(
            color: context.glass.onGlassMuted,
          ),
        ),
      ],
    );
  }
}

/// Who moved how much work.
///
/// Cases **and** transitions, because a case counts once per user however many
/// times they touched it: the two figures together say whether somebody
/// carried a few cases a long way or many cases one step, and either alone
/// would read as the other.
class DashboardUserWorkList extends StatelessWidget {
  const DashboardUserWorkList({super.key, required this.rows});

  final List<UserCaseWorkModel> rows;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final peak = rows.fold<int>(
      1,
      (max, row) => row.casesWorked > max ? row.casesWorked : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.userName ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                    ),
                    Text(
                      '${row.casesWorked} حالة · ${row.transitionCount} نقلة',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: row.casesWorked / peak,
                    minHeight: 6,
                    backgroundColor: glass.fillColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
