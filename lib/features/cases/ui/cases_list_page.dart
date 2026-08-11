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
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_filters_sheet.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/cases_list_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The cases list screen. Adding a case is a separate route (pushed by the
/// add button) rather than a second tab — same shape as every other feature
/// in the app.
class CasesListPage extends StatelessWidget {
  const CasesListPage({super.key});

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
      child: const _CasesListView(),
    );
  }
}

class _CasesListView extends StatefulWidget {
  const _CasesListView();

  @override
  State<_CasesListView> createState() => _CasesListViewState();
}

class _CasesListViewState extends State<_CasesListView> {
  final _scrollController = ScrollController();

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
      floatingActionButton: Builder(
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
      body: SafeArea(child: CasesListBody(scrollController: _scrollController)),
    );
  }
}
