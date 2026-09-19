import 'dart:async';

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/widgets/doctor_audience_sheet.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/priority_allowance/priority_allowance_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/priority_allowance/priority_allowance_state.dart';
import 'package:dental_lab_app/features/case_priorities/ui/widgets/priority_allowance_sheet.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_state.dart';
import 'package:dental_lab_app/features/case_priorities/ui/widgets/case_priorities_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CasePrioritiesListPage extends StatelessWidget {
  const CasePrioritiesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Inactive rows are included here and only here: this is the screen
      // where a retired priority has to stay visible to be edited back on.
      create: (_) =>
          getIt<CasePrioritiesCubit>()
            ..getCasePriorities(includeInactive: true),
      child: const _CasePrioritiesListView(),
    );
  }
}

class _CasePrioritiesListView extends StatefulWidget {
  const _CasePrioritiesListView();

  @override
  State<_CasePrioritiesListView> createState() =>
      _CasePrioritiesListViewState();
}

class _CasePrioritiesListViewState extends State<_CasePrioritiesListView> {
  final _scrollController = ScrollController();

  /// Last successfully loaded priorities, kept so a refresh can show the
  /// existing rows instead of replacing them with the loading skeleton.
  List<CasePriorityModel>? _lastPriorities;

  /// The add button collapses to an icon once the user starts scrolling, so a
  /// wide button never sits on top of the rows they are reading.
  bool _addButtonExtended = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final shouldExtend = _scrollController.offset < 40;
    if (shouldExtend == _addButtonExtended) return;
    setState(() => _addButtonExtended = shouldExtend);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Hands one priority's free allowance to a group of doctors.
  ///
  /// Two questions in order — who, then how much — because the second is
  /// meaningless without the first, and showing them together would let a user
  /// type figures they then have nobody to apply to.
  Future<void> _assignAllowance(CasePriorityModel priority) async {
    final doctorsResult = await getIt<DoctorsRepo>().getDoctors();
    if (!mounted) return;

    final doctors = doctorsResult.fold(
      (_) => const <DoctorModel>[],
      (list) => [
        for (final doctor in list)
          if (doctor.isActive) doctor,
      ],
    );
    if (doctors.isEmpty) {
      showToast(message: 'تعذّر جلب قائمة الأطباء', state: ToastState.error);
      return;
    }

    // Who already has this allowance, so reopening the sheet shows the last
    // answer instead of an empty list the user has to rebuild from memory.
    final assigned = await _loadAssignedDoctors(priority, doctors);
    if (!mounted) return;

    if (assigned.unreadable > 0) {
      showToast(
        message:
            'تعذّر التحقق من حصة ${assigned.unreadable} طبيب — '
            'قد لا يظهر تحديدهم',
        state: ToastState.warning,
      );
    }

    final chosenIds = await showDoctorAudienceSheet(
      context,
      doctors: doctors,
      title: 'حصة "${priority.displayName}" — لمن؟',
      assignedIds: assigned.assignedIds,
    );
    if (chosenIds == null || chosenIds.isEmpty || !mounted) return;

    final chosen = [
      for (final doctor in doctors)
        if (chosenIds.contains(doctor.id))
          (id: doctor.id, name: doctor.fullName),
    ];

    final allowance = await showPriorityAllowanceSheet(
      context,
      priority: priority,
      doctorCount: chosen.length,
    );
    if (allowance == null || !mounted) return;

    await _runApply(priority: priority, doctors: chosen, allowance: allowance);
  }

  /// Reads the current assignment behind a blocking spinner.
  ///
  /// It is one request per doctor, so it is not instant; without the barrier
  /// the sheet would open on an empty selection and then have to be corrected
  /// under the user's hands.
  Future<({Set<String> assignedIds, int unreadable})> _loadAssignedDoctors(
    CasePriorityModel priority,
    List<DoctorModel> doctors,
  ) async {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );

    final assigned = await getIt<CasePrioritiesRepo>()
        .getDoctorsWithPriorityOverride(
          priorityId: priority.id,
          doctorIds: [for (final doctor in doctors) doctor.id],
        );

    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    return assigned;
  }

  /// Runs the per-doctor writes behind a progress dialog.
  ///
  /// There is no bulk endpoint, so this is one request per doctor. A blocking
  /// dialog rather than a toast: leaving the screen mid-run would strand the
  /// remaining doctors on their old allowance with nothing said.
  Future<void> _runApply({
    required CasePriorityModel priority,
    required List<({String id, String name})> doctors,
    required PriorityAllowanceResult allowance,
  }) async {
    final cubit = getIt<PriorityAllowanceCubit>();

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            BlocBuilder<PriorityAllowanceCubit, PriorityAllowanceState>(
              bloc: cubit,
              builder: (context, state) => _ApplyProgressDialog(state: state),
            ),
      ),
    );

    await cubit.apply(
      priorityId: priority.id,
      doctors: doctors,
      freePerMonth: allowance.freePerMonth,
      surchargeAmount: allowance.surchargeAmount,
    );

    final state = cubit.state;
    await cubit.close();
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    if (state is! PriorityAllowanceDone) return;

    showToast(
      message: state.isClean
          ? (allowance.isReset
                ? 'تم إرجاع ${state.succeeded} طبيب لإعداد المخبر'
                : 'تم تطبيق الحصة على ${state.succeeded} طبيب')
          // A partial result is a real outcome, not a plain failure: saying
          // only "failed" would hide the doctors who did get their allowance.
          : 'تم على ${state.succeeded}، وتعذّر على ${state.failed.length}'
                '${state.firstError == null ? '' : ' — ${state.firstError}'}',
      state: state.isClean ? ToastState.success : ToastState.error,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CasePriorityModel priority,
  ) async {
    final cubit = context.read<CasePrioritiesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الأولوية',
      message: 'هل أنت متأكد من حذف أولوية "${priority.displayName}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteCasePriority(priority.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(
        currentRoute: Routes.casePrioritiesListScreen,
      ),
      appBar: GlassAppBar(
        title: Text(
          'أولويات الحالات',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) =>
            GlassAddButton(
              label: 'إضافة أولوية',
              isExtended: _addButtonExtended,
              onPressed: () async {
                await context.push(Routes.casePriorityFormScreen);
                if (context.mounted) {
                  context.read<CasePrioritiesCubit>().getCasePriorities(
                    includeInactive: true,
                  );
                }
              },
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            ),
      ),
      body: SafeArea(
        child: BlocConsumer<CasePrioritiesCubit, CasePrioritiesState>(
          listener: (context, state) {
            switch (state) {
              case CasePriorityDeleted():
                showToast(
                  message: 'تم حذف الأولوية',
                  state: ToastState.success,
                );
              case CasePriorityDeleteError(:final message):
                showToast(message: message, state: ToastState.error);
              case CasePrioritiesSeeded():
                showToast(
                  message: 'تمت إضافة الأولويات الافتراضية',
                  state: ToastState.success,
                );
              case CasePrioritiesSeedError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! CasePriorityDeleted &&
              current is! CasePriorityDeleteError &&
              current is! CasePrioritiesSeeded &&
              current is! CasePrioritiesSeedError,
          builder: (context, state) {
            if (state is CasePrioritiesLoaded) {
              _lastPriorities = state.priorities;
            }

            final priorities = switch (state) {
              CasePrioritiesLoaded(:final priorities) => priorities,
              CasePrioritiesLoading() => _lastPriorities,
              _ => null,
            };

            return AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: switch ((state, priorities)) {
                (_, final List<CasePriorityModel> loaded) when loaded.isEmpty =>
                  _EmptyState(
                    key: const ValueKey('case-priorities-empty'),
                    onSeedDefaults: () =>
                        context.read<CasePrioritiesCubit>().seedDefaults(),
                  ),
                (_, final List<CasePriorityModel> loaded) =>
                  CasePrioritiesListView(
                    key: const ValueKey('case-priorities-loaded'),
                    priorities: loaded,
                    scrollController: _scrollController,
                    onDelete: (priority) => _confirmDelete(context, priority),
                    onAssign: _assignAllowance,
                  ),
                (CasePrioritiesError(:final message), null) => Center(
                  key: const ValueKey('case-priorities-error'),
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
                _ => const Padding(
                  key: ValueKey('case-priorities-loading'),
                  padding: EdgeInsets.only(top: 24),
                  child: GlassListSkeleton(),
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

/// Shown while the lab has no priorities. Cases cannot be created without
/// one, so this offers the API's default set as a one-tap way out instead of
/// making the user type four rows by hand.
class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key, required this.onSeedDefaults});

  final VoidCallback onSeedDefaults;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: glass.surfaceGradient,
                    border: Border.all(color: glass.strokeColor),
                  ),
                  child: Icon(
                    Icons.flag_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد أولويات بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أولوية بالضغط على زر الإضافة، أو ابدأ بالأولويات الافتراضية',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: onSeedDefaults,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('إضافة الأولويات الافتراضية'),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: AppMotion.base,
          curve: AppMotion.enter,
        );
  }
}

/// Progress for a run that is one request per doctor.
///
/// A count rather than a spinner: the user chose a city and is now waiting on
/// as many writes as it had doctors, and "12 من 40" is the difference between
/// waiting and wondering whether it hung.
class _ApplyProgressDialog extends StatelessWidget {
  const _ApplyProgressDialog({required this.state});

  final PriorityAllowanceState state;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final applying = state is PriorityAllowanceApplying
        ? state as PriorityAllowanceApplying
        : null;

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'جارٍ تطبيق الحصة...',
            style: AppTextStyles.font16MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(value: applying?.fraction),
          if (applying != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${applying.done} من ${applying.total}',
              textAlign: TextAlign.center,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
