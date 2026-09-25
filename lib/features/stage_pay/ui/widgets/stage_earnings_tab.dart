import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_card.dart';
import 'package:dental_lab_app/features/stage_pay/data/models/stage_pay_models.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_earnings/stage_earnings_cubit.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_earnings/stage_earnings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What finished stages paid over a period, for everyone or one employee.
class StageEarningsTab extends StatelessWidget {
  const StageEarningsTab({super.key});

  Future<void> _pickRange(
    BuildContext context,
    StageEarningsState state,
  ) async {
    final cubit = context.read<StageEarningsCubit>();
    final now = DateTime.now();

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(start: state.from, end: state.to),
    );
    if (range == null) return;

    await cubit.setRange(range.start, range.end);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return BlocBuilder<StageEarningsCubit, StageEarningsState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.screen,
                0,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickRange(context, state),
                    icon: const Icon(Icons.date_range_outlined, size: 18),
                    label: Text(
                      '${ApiTime.formatDate(state.from)} — '
                      '${ApiTime.formatDate(state.to)}',
                    ),
                  ),
                  if (state.employees.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: DropdownButtonFormField<String?>(
                        initialValue: state.employeeId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'الموظف',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            child: Text('الجميع'),
                          ),
                          for (final employee in state.employees)
                            DropdownMenuItem<String?>(
                              value: employee.id,
                              child: Text(
                                employee.fullName.isEmpty
                                    ? '—'
                                    : employee.fullName,
                              ),
                            ),
                        ],
                        onChanged: context
                            .read<StageEarningsCubit>()
                            .setEmployee,
                      ),
                    ),
                ],
              ),
            ),
            if (state is StageEarningsLoaded && state.rows.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.sm,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'المجموع: ${state.total.toStringAsFixed(2)}',
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: switch (state) {
                StageEarningsLoaded(:final rows) when rows.isEmpty => Center(
                  child: Text(
                    'لا أجور مراحل في هذه الفترة',
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
                StageEarningsLoaded(:final rows) => AdaptiveCollection(
                  items: rows,
                  cardHeight: 104,
                  onRefresh: context.read<StageEarningsCubit>().load,
                  itemBuilder: (context, row, _) => _EarningCard(row: row),
                ),
                StageEarningsError(:final message) => Center(
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
                StageEarningsLoading() => const Center(
                  child: CustomCircleProgressIndiacatorWidget(),
                ),
              },
            ),
          ],
        );
      },
    );
  }
}

class _EarningCard extends StatelessWidget {
  const _EarningCard({required this.row});

  final EmployeeStageEarningModel row;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final muted = AppTextStyles.font12RegularHint.copyWith(
      color: glass.onGlassMuted,
    );
    // A voided row stays in the history but pays nothing — struck through,
    // and left out of the total.
    final strike = row.isVoided ? TextDecoration.lineThrough : null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.employeeName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              Text(
                row.amount.toStringAsFixed(2),
                style: AppTextStyles.font14MediumText.copyWith(
                  color: row.isVoided ? glass.onGlassMuted : glass.onGlass,
                  decoration: strike,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${row.stageDisplayName} · ${row.restorationTypeDisplayName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted.copyWith(decoration: strike),
          ),
          const SizedBox(height: 2),
          Text(
            [
              if (row.caseNumber != null) 'حالة ${row.caseNumber}',
              '${row.quantity} × ${row.unitAmount.toStringAsFixed(2)} '
                  '${row.basis.label}',
              if (row.earnedAt != null) ApiTime.formatDate(row.earnedAt!),
              if (row.isVoided) 'ملغى',
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ],
      ),
    );
  }
}
