import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/badge_variant.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_list_item_widget.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_breakdown_models.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:dental_lab_app/features/dashboard/logic/dashboard/dashboard_cubit.dart';
import 'package:dental_lab_app/features/dashboard/logic/dashboard/dashboard_state.dart';
import 'package:dental_lab_app/features/dashboard/ui/widgets/dashboard_breakdown_bars.dart';
import 'package:dental_lab_app/features/dashboard/ui/widgets/dashboard_lists.dart';
import 'package:dental_lab_app/features/dashboard/ui/widgets/dashboard_flow_panels.dart';
import 'package:dental_lab_app/features/dashboard/ui/widgets/dashboard_section_shell.dart';
import 'package:dental_lab_app/features/dashboard/ui/widgets/dashboard_summary_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The home dashboard.
///
/// The counters and recent cases arrive with the screen; everything below is
/// requested the first time the user scrolls toward it. See [DashboardCubit]
/// for why the eight endpoints are split that way.
class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  final _scrollController = ScrollController();

  /// How close to the deferred half the user has to get before it is fetched.
  /// Generous on purpose — the request should be in flight by the time the
  /// section scrolls into view, not starting as it lands.
  static const double _deferredTriggerOffset = 120;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset < _deferredTriggerOffset) return;
    // The cubit ignores repeat calls once the deferred half is requested, so
    // this does not need its own guard flag.
    context.read<DashboardCubit>().loadDeferred();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    // A one-time read, not watched: matches every other permission check in
    // the app (drawer, dashboard tiles) — the session does not change under
    // a mounted screen.
    final permissions = getIt<SessionCubit>().state;
    final canReadCases = permissions.canRead(PermissionName.cases);
    final canReadDoctors = permissions.canRead(PermissionName.doctor);

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              const _Greeting(),
              const SizedBox(height: AppSpacing.sectionGap),

              DashboardSectionShell<DashboardSummaryModel>(
                title: 'نظرة عامة',
                section: state.summary,
                onRetry: cubit.loadEssentials,
                skeletonRows: 2,
                // A summary is never "empty" — zeros are a real answer.
                isEmpty: (_) => false,
                builder: (context, summary) =>
                    DashboardSummaryTiles(summary: summary),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              // Every row here opens a case — hidden rather than shown to a
              // user who cannot read Cases, same as the summary tiles.
              if (canReadCases) ...[
                DashboardSectionShell<List<CaseListItemModel>>(
                  title: 'أحدث الحالات',
                  section: state.recentCases,
                  onRetry: cubit.loadEssentials,
                  emptyMessage: 'لا توجد حالات بعد',
                  trailing: TextButton(
                    onPressed: () => context.push(Routes.casesListScreen),
                    child: const Text('عرض الكل'),
                  ),
                  builder: (context, cases) => _RecentCases(cases: cases),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],

              // The funnel goes first because it is the one breakdown whose
              // column sums to the laboratory's total — the stage chart below
              // describes only the cases inside production, and a reader who
              // met that one first would try to add it up.
              DashboardSectionShell<List<CasePhaseCountModel>>(
                title: 'دورة حياة الحالات',
                section: state.casesByPhase,
                onRetry: () => cubit.loadDeferred(force: true),
                emptyMessage: 'لا توجد حالات',
                builder: (context, phases) =>
                    DashboardPhaseFunnel(phases: phases),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              DashboardSectionShell<List<CaseFlowPointModel>>(
                title: 'الوارد مقابل المسلَّم',
                section: state.caseFlow,
                onRetry: () => cubit.loadDeferred(force: true),
                emptyMessage: 'لا توجد حركة في هذه الفترة',
                builder: (context, points) =>
                    DashboardCaseFlowChart(points: points),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              DashboardSectionShell<List<CaseStageCountModel>>(
                title: 'الحالات حسب المرحلة',
                section: state.casesByStage,
                onRetry: () => cubit.loadDeferred(force: true),
                emptyMessage: 'لا توجد حالات في أي مرحلة',
                builder: (context, stages) => DashboardBreakdownBars(
                  bars: [
                    for (final stage in stages)
                      BreakdownBar(
                        label: stage.label.isEmpty ? 'بدون مرحلة' : stage.label,
                        value: stage.count.toDouble(),
                        color: badgeVariantColor(context, stage.badgeVariant),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              DashboardSectionShell<List<CasePriorityCountModel>>(
                title: 'الحالات حسب الأولوية',
                section: state.casesByPriority,
                onRetry: () => cubit.loadDeferred(force: true),
                emptyMessage: 'لا توجد حالات بأولوية محددة',
                builder: (context, priorities) => DashboardBreakdownBars(
                  bars: [
                    for (final priority in priorities)
                      BreakdownBar(
                        label: priority.label.isEmpty
                            ? 'بدون أولوية'
                            : priority.label,
                        value: priority.count.toDouble(),
                        // The counts endpoint sends no badgeVariant for
                        // priorities, so these share one accent instead of
                        // borrowing colours that would not match the badge the
                        // same priority shows on a case row.
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              DashboardSectionShell<List<UpcomingDueCaseModel>>(
                title: 'حالات تستحق قريباً',
                section: state.upcomingDueCases,
                onRetry: () => cubit.loadDeferred(force: true),
                emptyMessage: 'لا توجد حالات مستحقة خلال الأيام القادمة',
                builder: (context, cases) =>
                    DashboardUpcomingDueList(cases: cases),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              // Every row opens a doctor's detail screen — hidden rather than
              // shown to a user who cannot read Users (which is what gates
              // that screen), same reasoning as the cases section above.
              if (canReadDoctors) ...[
                DashboardSectionShell<List<TopDoctorModel>>(
                  title: 'الأطباء الأكثر إرسالاً',
                  section: state.topDoctors,
                  onRetry: () => cubit.loadDeferred(force: true),
                  emptyMessage: 'لا يوجد أطباء بعد',
                  builder: (context, doctors) =>
                      DashboardTopDoctorsList(doctors: doctors),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],

              DashboardSectionShell<List<MonthlyRevenueModel>>(
                title: 'الإيرادات الشهرية',
                section: state.revenueByMonth,
                onRetry: () => cubit.loadDeferred(force: true),
                emptyMessage: 'لا توجد إيرادات مسجلة',
                builder: (context, months) => _RevenueBars(months: months),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              DashboardSectionShell<List<UserCaseWorkModel>>(
                title: 'عمل الفريق',
                section: state.userCaseWork,
                onRetry: () => cubit.loadDeferred(force: true),
                emptyMessage: 'لا يوجد عمل مسجّل في هذه الفترة',
                builder: (context, rows) => DashboardUserWorkList(rows: rows),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              DashboardSectionShell<List<RecentActivityModel>>(
                title: 'آخر النشاطات',
                section: state.recentActivity,
                onRetry: () => cubit.loadDeferred(force: true),
                emptyMessage: 'لا يوجد نشاط بعد',
                builder: (context, activity) =>
                    DashboardRecentActivityList(activity: activity),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final laboratoryName =
        CacheHelper.getData(key: CacheKeys.laboratoryName) as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مرحباً بك',
          style: AppTextStyles.font24BoldText.copyWith(color: glass.onGlass),
        ),
        if (laboratoryName != null && laboratoryName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            laboratoryName,
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _RecentCases extends StatelessWidget {
  const _RecentCases({required this.cases});

  final List<CaseListItemModel> cases;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < cases.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          // Reuses the cases list's own row so a case looks identical wherever
          // it appears. Delete is not offered here — the dashboard is a
          // read-only overview, and a destructive action a swipe away from a
          // summary is a mis-tap waiting to happen.
          CaseListItemWidget(
            caseNumber: cases[i].caseNumber ?? '',
            patientName: cases[i].patientName ?? '',
            doctorName: cases[i].doctorName ?? '',
            stageName: cases[i].stageLabel,
            productionSummary: cases[i].productionSummaryLabel,
            stageColor: badgeVariantColor(
              context,
              cases[i].stage.stageBadgeVariant,
            ),
            isLate: cases[i].stage.isLate,
            priorityLabel: cases[i].priorityLabel,
            priorityColor: Theme.of(context).colorScheme.primary,
            onTap: () =>
                context.push(Routes.caseDetailScreen, extra: cases[i].id),
            onDelete: null,
          ),
        ],
      ],
    );
  }
}

class _RevenueBars extends StatelessWidget {
  const _RevenueBars({required this.months});

  final List<MonthlyRevenueModel> months;

  /// `2026-08` → `08/2026`. Kept numeric rather than named: the app has no
  /// month-name table yet, and a wrong name is worse than a number.
  String _monthLabel(DateTime? month) {
    if (month == null) return '—';
    return '${month.month.toString().padLeft(2, '0')}/${month.year}';
  }

  /// Thousands separators, no currency symbol — the endpoint sends no currency
  /// and guessing one would misstate money.
  String _amount(double value) {
    final whole = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return DashboardBreakdownBars(
      bars: [
        for (final month in months)
          BreakdownBar(
            label: _monthLabel(month.month),
            value: month.revenue,
            color: accent,
            valueLabel: _amount(month.revenue),
          ),
      ],
    );
  }
}

/// Shimmer shown while the very first load is in flight, before any section
/// has a shape to hold.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: const [
        GlassSkeletonBox(width: 140, height: 28),
        SizedBox(height: AppSpacing.sectionGap),
        GlassSkeletonBox(height: 96),
        SizedBox(height: AppSpacing.md),
        GlassSkeletonBox(height: 96),
      ],
    );
  }
}
