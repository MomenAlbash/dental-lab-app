import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_filter_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_filters_sheet.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_search_field.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/cases_list_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// The cases list screen. Adding a case is a separate route (pushed by the
/// add button) rather than a second tab — same shape as every other feature
/// in the app.
class CasesListPage extends StatelessWidget {
  const CasesListPage({super.key, this.showAddButton = true});

  /// Whether the screen carries its own "إضافة حالة" action.
  ///
  /// Off when the page is hosted as a tab of the main shell: there the raised
  /// `+` in the bottom bar is the single entry point for creating a case, and
  /// a second add button floating over the same list would be two controls for
  /// one job. Reached on its own from the drawer there is no bottom bar, so it
  /// defaults to on.
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CasesCubit>()..getCases()),
        // Rows carry only the priority's id and name; the list is what turns
        // that into the badge colour shown on each row. Same active-only
        // scope as the filter sheet, so a row's colour and its filter chip
        // always come from the same list.
        BlocProvider(
          create: (_) => getIt<CasePrioritiesCubit>()..getCasePriorities(),
        ),
      ],
      child: _CasesListView(showAddButton: showAddButton),
    );
  }
}

class _CasesListView extends StatefulWidget {
  const _CasesListView({required this.showAddButton});

  final bool showAddButton;

  @override
  State<_CasesListView> createState() => _CasesListViewState();
}

class _CasesListViewState extends State<_CasesListView> {
  final _scrollController = ScrollController();

  /// The add button collapses to an icon once the user starts scrolling, so a
  /// wide button never sits on top of the rows they are reading.
  bool _addButtonExtended = true;

  bool _exportingCsv = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _exportCsv(BuildContext context) async {
    final cubit = context.read<CasesCubit>();
    setState(() => _exportingCsv = true);

    // The same filters and search term the list is showing right now — an
    // export that silently widened to everything would disagree with the
    // screen the user just narrowed.
    final result = await getIt<CasesRepo>().exportCasesCsv(
      search: cubit.search,
      filters: cubit.filters,
    );

    if (!mounted) return;
    setState(() => _exportingCsv = false);

    await result.fold(
      (failure) async =>
          showToast(message: failure.errorMessage, state: ToastState.error),
      // Shared rather than opened directly: a raw file:// launch crashes on
      // Android 7+ without a FileProvider, and the share sheet lets the user
      // pick a spreadsheet app or just save the file — same hand-off already
      // used for the invoice PDF.
      (path) async {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(path)], text: 'تصدير الحالات'),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.casesListScreen),
      appBar: GlassAppBar(
        title: Text(
          'الحالات',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
        actions: [
          // "My tasks": the same list, narrowed to the stages this login is
          // assigned. A toggle rather than a screen of its own — it is the
          // ordinary list with a server-resolved filter, and everything else
          // on this screen (search, tabs, the date segment) still applies.
          BlocBuilder<CasesCubit, CasesState>(
            builder: (context, _) {
              final isMyTasks = context.read<CasesCubit>().isMyTasks;

              return IconButton(
                tooltip: isMyTasks ? 'عرض كل الحالات' : 'مهامي',
                isSelected: isMyTasks,
                icon: const Icon(Icons.assignment_ind_outlined),
                selectedIcon: Icon(
                  Icons.assignment_ind,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () =>
                    context.read<CasesCubit>().setMyTasks(!isMyTasks),
              );
            },
          ),
          // Beside search, because it is the same act: finding one case. The
          // difference is that the ticket in the user's hand already names it.
          IconButton(
            tooltip: 'مسح باركود حالة أو تعويض',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push(Routes.barcodeScannerScreen),
          ),
          IconButton(
            tooltip: 'تصدير CSV',
            icon: _exportingCsv
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_outlined),
            onPressed: _exportingCsv ? null : () => _exportCsv(context),
          ),
          BlocBuilder<CasesCubit, CasesState>(
            builder: (context, state) {
              final activeCount = context
                  .read<CasesCubit>()
                  .filters
                  .activeCount;
              return GlassFilterButton(
                activeCount: activeCount,
                onPressed: () => openCaseFiltersSheet(context),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton:
          !widget.showAddButton ||
              !getIt<SessionCubit>().state.canEdit(PermissionName.cases)
          ? null
          : Builder(
              builder: (context) =>
                  GlassAddButton(
                    label: 'إضافة حالة',
                    isExtended: _addButtonExtended,
                    onPressed: () async {
                      await context.push(Routes.caseFormScreen);
                      if (context.mounted) {
                        context.read<CasesCubit>().getCases();
                      }
                    },
                  ).animate().scale(
                    duration: AppMotion.base,
                    curve: AppMotion.emphasized,
                    begin: const Offset(0.6, 0.6),
                  ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Above the list, not inside the filter sheet: looking a case up
            // by its number is the quick job, and it should not cost two taps.
            const CaseSearchField(),
            Expanded(child: CasesListBody(scrollController: _scrollController)),
          ],
        ),
      ),
    );
  }
}
