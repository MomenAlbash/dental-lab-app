import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_state.dart';
import 'package:dental_lab_app/features/cases/ui/case_form_page.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_filters_sheet.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/cases_list_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The main cases screen: a bottom nav bar with two tabs — view cases and add
/// a case. Both tabs share one [CasesCubit] so a newly created case refreshes
/// the list immediately.
class CasesShellPage extends StatelessWidget {
  const CasesShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CasesCubit>()..getCases(),
      child: const _CasesShellView(),
    );
  }
}

class _CasesShellView extends StatefulWidget {
  const _CasesShellView();

  @override
  State<_CasesShellView> createState() => _CasesShellViewState();
}

class _CasesShellViewState extends State<_CasesShellView> {
  int _index = 0;

  void _onCaseCreated() {
    setState(() => _index = 0);
    context.read<CasesCubit>().getCases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.casesListScreen),
      appBar: AppBar(
        title: Text(
          _index == 0 ? 'الحالات' : 'إضافة حالة',
          style: AppTextStyles.font18MediumText,
        ),
        actions: [
          if (_index == 0)
            BlocBuilder<CasesCubit, CasesState>(
              builder: (context, state) {
                final activeCount = context.read<CasesCubit>().filters.activeCount;
                return IconButton(
                  onPressed: () => openCaseFiltersSheet(context),
                  icon: Badge(
                    label: Text('$activeCount'),
                    isLabelVisible: activeCount > 0,
                    child: const Icon(Icons.filter_list),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            const CasesListBody(),
            CaseFormPage(onCreated: _onCaseCreated),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'الحالات',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'إضافة حالة',
          ),
        ],
      ),
    );
  }
}
