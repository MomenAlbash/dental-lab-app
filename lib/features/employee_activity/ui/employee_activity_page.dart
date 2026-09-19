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
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/employee_activity/data/models/employee_activity_model.dart';
import 'package:dental_lab_app/features/employee_activity/logic/employee_activity/employee_activity_cubit.dart';
import 'package:dental_lab_app/features/employee_activity/ui/widgets/activity_daily_list.dart';
import 'package:dental_lab_app/features/employee_activity/ui/widgets/activity_filters_sheet.dart';
import 'package:dental_lab_app/features/employee_activity/ui/widgets/activity_summary_panel.dart';
import 'package:dental_lab_app/features/employee_activity/ui/widgets/activity_timeline_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// How much work moved through whom, over a period.
///
/// **Reads history — it is not a new clock.** The per-stage work timers are
/// deliberately off, so nothing here answers "how long did this take"; every
/// figure is a count of events that were already recorded. Saying that plainly
/// on the screen matters, because a report of employee names and numbers is
/// read as a productivity measure unless it says what it actually measured.
class EmployeeActivityPage extends StatelessWidget {
  const EmployeeActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EmployeeActivityCubit>()..load(),
      child: const _EmployeeActivityView(),
    );
  }
}

class _EmployeeActivityView extends StatefulWidget {
  const _EmployeeActivityView();

  @override
  State<_EmployeeActivityView> createState() => _EmployeeActivityViewState();
}

class _EmployeeActivityViewState extends State<_EmployeeActivityView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  )..addListener(_onTabChanged);

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  /// The events are the heaviest of the three reads and most sessions never
  /// leave the summary, so they are fetched when the tab is actually opened.
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 2) {
      context.read<EmployeeActivityCubit>().loadTimeline();
    }
  }

  Future<void> _openFilters(BuildContext context) async {
    final cubit = context.read<EmployeeActivityCubit>();

    final filters = await showActivityFiltersSheet(
      context,
      initial: cubit.filters,
    );
    if (filters == null) return;

    await cubit.load(filters: filters);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canRead = getIt<SessionCubit>().state.canRead(
      PermissionName.statistics,
    );

    return GlassScaffold(
      drawer: const AppDrawerWidget(
        currentRoute: Routes.employeeActivityScreen,
      ),
      appBar: GlassAppBar(
        title: Text(
          'نشاط الفريق',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
        actions: [
          if (canRead)
            IconButton(
              tooltip: 'الفلاتر',
              onPressed: () => _openFilters(context),
              icon: const Icon(Icons.filter_alt_outlined),
            ),
          if (canRead)
            IconButton(
              tooltip: 'تصدير',
              onPressed: () =>
                  context.read<EmployeeActivityCubit>().export(),
              icon: const Icon(Icons.download_outlined),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ملخّص'),
            Tab(text: 'يومي'),
            Tab(text: 'الأحداث'),
          ],
        ),
      ),
      body: SafeArea(
        child: !canRead
            ? const _NoAccess()
            : BlocConsumer<EmployeeActivityCubit, EmployeeActivityState>(
                listenWhen: (previous, current) =>
                    current is EmployeeActivityActionError ||
                    current is EmployeeActivityExported,
                listener: (context, state) {
                  switch (state) {
                    case EmployeeActivityActionError(:final message):
                      showToast(message: message, state: ToastState.error);
                    case EmployeeActivityExported(:final bytes):
                      showToast(
                        message:
                            'جاهز التصدير (${bytes.length ~/ 1024} ك.ب) — '
                            'احفظوه من المشاركة',
                        state: ToastState.success,
                      );
                    default:
                      break;
                  }
                },
                buildWhen: (previous, current) =>
                    current is! EmployeeActivityActionError &&
                    current is! EmployeeActivityExported,
                builder: (context, state) => switch (state) {
                  EmployeeActivityLoaded() => Column(
                    children: [
                      _PeriodBanner(filters: state.filters),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            ActivitySummaryPanel(summary: state.summary),
                            ActivityDailyList(rows: state.daily),
                            ActivityTimelineList(
                              timeline: state.timeline,
                              isLoadingMore: state.isLoadingMore,
                              onLoadMore: () => context
                                  .read<EmployeeActivityCubit>()
                                  .loadMoreTimeline(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  EmployeeActivityError(:final message) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
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
      ),
    );
  }
}

/// The window these figures cover.
///
/// Stated at the top rather than left in the filter sheet: a count without the
/// period it covers is not a fact, and this is a report people screenshot.
class _PeriodBanner extends StatelessWidget {
  const _PeriodBanner({required this.filters});

  final EmployeeActivityFiltersModel filters;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final from = filters.from;
    final to = filters.to;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 16, color: glass.onGlassMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              [
                if (from != null && to != null)
                  '${ApiTime.formatDate(from)} → ${ApiTime.formatDate(to)}'
                else
                  'كل الفترة',
                if (!filters.includeReturns) 'بلا مرتجعات',
                if (!filters.includeRejected) 'بلا مرفوضة',
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

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: glass.onGlassMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا تملك صلاحية عرض تقارير النشاط',
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
