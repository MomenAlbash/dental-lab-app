import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:dental_lab_app/features/case_priorities/logic/doctor_quota/doctor_quota_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/doctor_quota/doctor_quota_state.dart';
import 'package:dental_lab_app/features/case_priorities/ui/widgets/priority_allowance_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This doctor's free allowance for every priority, with what is left of it
/// this month.
///
/// The doctor-first view of the same data the priorities screen hands out
/// priority-first. This is where "سريع: ٦ لهذا الطبيب، ٥ لغيره" is actually
/// read and edited — one screen, one doctor, every priority.
class DoctorQuotaSection extends StatelessWidget {
  const DoctorQuotaSection({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DoctorQuotaCubit>()..load(doctorId),
      child: const _QuotaView(),
    );
  }
}

class _QuotaView extends StatelessWidget {
  const _QuotaView();

  Future<void> _edit(BuildContext context, PriorityQuotaLineModel line) async {
    final cubit = context.read<DoctorQuotaCubit>();

    final result = await showPriorityAllowanceSheet(
      context,
      // The sheet takes a priority so it can show the lab's own default to
      // depart from; the doctor's current line supplies the starting figures.
      priority: CasePriorityModel(
        id: line.priorityId,
        nameAr: line.priorityNameAr,
        name: line.priorityName,
        isUnlimited: line.isUnlimited,
        freePerMonth: line.freePerMonth,
        surcharge: line.surcharge,
      ),
      doctorCount: 1,
    );
    if (result == null) return;

    await cubit.setAllowance(
      priorityId: line.priorityId,
      freePerMonth: result.freePerMonth,
      surchargeAmount: result.surchargeAmount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.caseWorkflow,
    );

    return BlocConsumer<DoctorQuotaCubit, DoctorQuotaState>(
      listener: (context, state) {
        if (state is DoctorQuotaMessage) {
          showToast(
            message: state.message,
            state: state.isError ? ToastState.error : ToastState.success,
          );
        }
      },
      buildWhen: (_, current) => current is! DoctorQuotaMessage,
      builder: (context, state) {
        final loaded = state is DoctorQuotaLoaded ? state : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassSectionTitle(
              'الحصص الشهرية',
              count: loaded?.quota.lines.length,
            ),
            const SizedBox(height: AppSpacing.md),

            switch (state) {
              DoctorQuotaError(:final message) => Text(
                message,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.error,
                ),
              ),
              DoctorQuotaLoaded(:final quota) =>
                quota.lines.isEmpty
                    ? Text(
                        'لا توجد أولويات معرّفة في المخبر بعد',
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final line in quota.lines) ...[
                            _QuotaRow(
                              line: line,
                              onEdit: canEdit && !(loaded?.isBusy ?? false)
                                  ? () => _edit(context, line)
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ),
              _ => const GlassSkeletonBox(height: 120),
            },
          ],
        );
      },
    );
  }
}

class _QuotaRow extends StatelessWidget {
  const _QuotaRow({required this.line, required this.onEdit});

  final PriorityQuotaLineModel line;
  final VoidCallback? onEdit;

  /// What is left, in words. The remaining count is the number that decides
  /// whether the next case is billed, so it leads.
  String get _remainingLabel {
    if (line.isUnlimited) return 'بلا حد شهري';
    if (line.freePerMonth <= 0) return 'بلا حالات مجانية';
    return 'بقي ${line.remainingFree} من ${line.freePerMonth} هذا الشهر';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;
    final isSpent = !line.isUnlimited && line.remainingFree <= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: glass.surfaceColor,
        border: Border.all(color: glass.strokeColor),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        line.priorityLabel.isEmpty ? '—' : line.priorityLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                    ),
                    // The difference between "this doctor's own arrangement"
                    // and "whatever the lab set" is the whole point of the
                    // screen; the same numbers mean different things.
                    if (line.isOverridden) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _Tag(text: 'مخصّص', color: accent),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _remainingLabel,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: isSpent ? glass.warning : glass.onGlassMuted,
                  ),
                ),
                if (line.surcharge > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'بعدها ${line.surcharge.toStringAsFixed(0)} للحالة',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'تعديل الحصة',
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, color: glass.onGlassMuted),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}
