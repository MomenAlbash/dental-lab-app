import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/features/employee_activity/data/models/employee_activity_model.dart';
import 'package:flutter/material.dart';

/// One row per employee per day.
class ActivityDailyList extends StatelessWidget {
  const ActivityDailyList({super.key, required this.rows});

  final List<EmployeeActivityDailyModel> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _Empty(text: 'لا يوجد نشاط في هذه الفترة');
    }

    return AdaptiveCollection<EmployeeActivityDailyModel>(
      items: rows,
      cardHeight: 168,
      itemBuilder: (context, row, _) => _DailyCard(row: row),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.row});

  final EmployeeActivityDailyModel row;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              Text(
                row.date ?? '—',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ],
          ),
          if (row.userRole?.trim().isNotEmpty ?? false)
            Text(
              row.userRole!,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),

          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 4,
            children: [
              _Chip(
                label: '${row.totalCount} حدث',
                color: Theme.of(context).colorScheme.primary,
              ),
              // Counted once per case however many times it was moved, so this
              // is how much of the lab's work passed through them — not how
              // often they pressed a button.
              _Chip(
                label: '${row.distinctCases} طلب',
                color: glass.info,
              ),
              if (row.returns > 0)
                _Chip(label: '${row.returns} مرتجع', color: glass.warning),
              if (row.scannerSessions > 0)
                _Chip(
                  label: '${row.scannerSessions} جلسة',
                  color: glass.success,
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          Text(
            // Named as a span, not as hours: it is the distance between the
            // first and last recorded move, so a gap in the middle is
            // invisible and a single event gives no span at all.
            'أول/آخر حركة: ${row.spanLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),

          if (row.topStages.isNotEmpty)
            Text(
              'الأكثر: '
              '${row.topStages.take(2).map((s) => '${s.displayName} (${s.count})').join('، ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline_outlined, size: 48, color: glass.onGlassMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
