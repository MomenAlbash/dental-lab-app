import 'dart:async';

import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:dental_lab_app/features/case_priorities/logic/priority_overview/priority_overview_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/ui/widgets/increase_allowance_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Who has what rush-priority allowance, and who has spent it.
///
/// The period is the server's, not a picker: allowances reset monthly, and
/// "٣ مستعملة" without the window it belongs to is not a fact — so the reset
/// date is stated at the top rather than left implicit.
class PriorityOverviewPage extends StatelessWidget {
  const PriorityOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PriorityOverviewCubit>()..load(),
      child: const _PriorityOverviewView(),
    );
  }
}

class _PriorityOverviewView extends StatefulWidget {
  const _PriorityOverviewView();

  @override
  State<_PriorityOverviewView> createState() => _PriorityOverviewViewState();
}

class _PriorityOverviewViewState extends State<_PriorityOverviewView> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    final cubit = context.read<PriorityOverviewCubit>();

    // The same debounce every search box in this app uses — a request per
    // keystroke is the commonest source of a screen feeling slow.
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => cubit.load(search: value.trim()),
    );
  }

  Future<void> _increase(
    BuildContext context,
    PriorityOverviewRowModel doctor,
    PriorityQuotaLineModel line,
  ) async {
    final cubit = context.read<PriorityOverviewCubit>();

    final request = await showIncreaseAllowanceDialog(
      context,
      doctorName: doctor.doctorName ?? '—',
      line: line,
    );
    if (request == null) return;

    await cubit.increase(
      doctorId: doctor.doctorId,
      priorityId: line.priorityId,
      body: request,
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.caseWorkflow,
    );

    return GlassScaffold(
      drawer: const AppDrawerWidget(
        currentRoute: Routes.priorityOverviewScreen,
      ),
      appBar: GlassAppBar(
        title: Text(
          'حصص الأولويات',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<PriorityOverviewCubit, PriorityOverviewState>(
          listenWhen: (previous, current) =>
              current is PriorityOverviewActionSuccess ||
              current is PriorityOverviewActionError,
          listener: (context, state) {
            switch (state) {
              case PriorityOverviewActionSuccess(:final message):
                showToast(message: message, state: ToastState.success);
              case PriorityOverviewActionError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! PriorityOverviewActionSuccess &&
              current is! PriorityOverviewActionError,
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: AppTextFormField(
                    controller: _searchController,
                    hintText: 'ابحث عن طبيب…',
                    prefixIcon: Icon(Icons.search, color: glass.onGlassMuted),
                    validator: (_) => null,
                    onChanged: _onSearch,
                  ),
                ),

                if (state is PriorityOverviewLoaded)
                  _PeriodBanner(overview: state.overview),

                Expanded(
                  child: switch (state) {
                    PriorityOverviewLoaded(:final overview) =>
                      overview.doctors.isEmpty
                          ? const _EmptyState()
                          : RefreshIndicator(
                              onRefresh: () =>
                                  context.read<PriorityOverviewCubit>().load(),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                itemCount: overview.doctors.length,
                                itemBuilder: (context, index) {
                                  final doctor = overview.doctors[index];
                                  return _DoctorCard(
                                    doctor: doctor,
                                    onIncrease: canEdit
                                        ? (line) =>
                                              _increase(context, doctor, line)
                                        : null,
                                  );
                                },
                              ),
                            ),
                    PriorityOverviewError(:final message) => Center(
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
                    _ => const Center(
                      child: CustomCircleProgressIndiacatorWidget(),
                    ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The period these figures belong to, and when they reset.
class _PeriodBanner extends StatelessWidget {
  const _PeriodBanner({required this.overview});

  final PriorityOverviewModel overview;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.event_repeat, size: 16, color: glass.onGlassMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              [
                'فترة ${overview.month}/${overview.year}',
                if (overview.periodResetsAt != null)
                  'تُصفَّر في ${ApiTime.formatDate(overview.periodResetsAt!)}',
                if (overview.overriddenCount > 0)
                  '${overview.overriddenCount} بشروط خاصة',
              ].join(' · '),
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor, this.onIncrease});

  final PriorityOverviewRowModel doctor;

  /// Null without permission to edit the workflow.
  final ValueChanged<PriorityQuotaLineModel>? onIncrease;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                  doctor.doctorName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              if (doctor.hasOverride)
                Text(
                  // The whole reason this screen exists: a directory of
                  // identical rows is not worth reading, the exceptions are.
                  'شروط خاصة',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          if (doctor.clinicName?.trim().isNotEmpty ?? false)
            Text(
              doctor.clinicName!,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),

          const SizedBox(height: AppSpacing.sm),
          for (final line in doctor.lines)
            _QuotaLine(
              line: line,
              onIncrease: onIncrease == null ? null : () => onIncrease!(line),
            ),
        ],
      ),
    );
  }
}

class _QuotaLine extends StatelessWidget {
  const _QuotaLine({required this.line, this.onIncrease});

  final PriorityQuotaLineModel line;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isExhausted = !line.isUnlimited && line.remainingFree <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.priorityLabel,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                Text(
                  line.isUnlimited
                      // Never limited and never billed — the counts below
                      // would be meaningless, so they are not shown at all.
                      ? 'غير محدودة'
                      : [
                          'مستعمَل ${line.usedThisMonth} من ${line.totalFree}',
                          if (line.bonusFree > 0)
                            'منها ${line.bonusFree} إضافية لهذه الفترة',
                          if (line.surcharge > 0)
                            'بعدها ${line.surchargeLabel}',
                        ].join(' · '),
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: isExhausted ? glass.warning : glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
          if (line.isOverridden)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: Icon(Icons.star, size: 14, color: glass.info),
            ),
          if (onIncrease != null && !line.isUnlimited)
            IconButton(
              tooltip: 'زيادة الحصة',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              onPressed: onIncrease,
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 48, color: glass.onGlassMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا يوجد أطباء بهذا البحث',
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
