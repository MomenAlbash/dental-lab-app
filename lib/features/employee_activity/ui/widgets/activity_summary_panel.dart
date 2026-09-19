import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/employee_activity/data/models/employee_activity_model.dart';
import 'package:flutter/material.dart';

/// The whole team over the chosen period.
class ActivitySummaryPanel extends StatelessWidget {
  const ActivitySummaryPanel({super.key, required this.summary});

  final EmployeeActivitySummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Tile(label: 'أحداث', value: '${summary.totalEvents}'),
              // People who moved something — not the headcount. A team of
              // twenty with four active is the finding, and showing the roster
              // size here would hide it.
              _Tile(label: 'موظف نشط', value: '${summary.activeEmployees}'),
              _Tile(label: 'طلب تم لمسه', value: '${summary.casesTouched}'),
              _Tile(label: 'جلسات سكنر', value: '${summary.scannerSessions}'),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          // Rework given its own line with a rate, because a busy period that
          // is mostly returns is the opposite of a productive one, and a raw
          // count beside three other counts reads like more throughput.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: glass.warning.withValues(alpha: 0.1),
              border: Border.all(color: glass.warning.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(AppRadius.glass),
            ),
            child: Row(
              children: [
                Icon(Icons.undo, size: 18, color: glass.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'مرتجعات: ${summary.returns} '
                    '(%${(summary.returnRate * 100).toStringAsFixed(1)} '
                    'من الأحداث)',
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          _Bars(
            title: 'حسب الموظف',
            rows: [
              for (final row in summary.byEmployee)
                (label: row.displayName, count: row.count),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          _Bars(
            title: 'حسب المرحلة',
            rows: [
              for (final row in summary.byStage)
                (label: row.displayName, count: row.count),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          _Bars(
            title: 'حسب اليوم',
            rows: [
              for (final row in summary.byDay)
                (label: row.date ?? '—', count: row.count),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          Text(
            // The one thing this report must not be mistaken for. The
            // per-stage work timers are off on purpose, so nothing here is a
            // measure of time spent.
            'هذا التقرير يعدّ الأحداث المسجّلة — لا يقيس وقت العمل.',
            textAlign: TextAlign.center,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled count with a bar scaled to the largest row.
class _Bars extends StatelessWidget {
  const _Bars({required this.title, required this.rows});

  final String title;
  final List<({String label, int count})> rows;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    if (rows.isEmpty) return const SizedBox.shrink();

    // Scaled to the biggest row rather than to the total: the question these
    // answer is "who did most", and against a total every bar in a busy lab
    // is a sliver.
    final max = rows.fold(0, (m, row) => row.count > m ? row.count : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTextStyles.font16MediumText.copyWith(color: glass.onGlass),
        ),
        const SizedBox(height: AppSpacing.sm),
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
                        row.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                    ),
                    Text(
                      '${row.count}',
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
                    value: max == 0 ? 0 : row.count / max,
                    minHeight: 6,
                    backgroundColor: glass.strokeColor,
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
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

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.font18MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }
}
