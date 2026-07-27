import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/case_form_page.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/cases_list_body.dart';
import 'package:dental_lab_app/features/home/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The app's main screen after login: a persistent bottom navigation bar with
/// three tabs — home, cases and add-case. The cases list and the add-case form
/// share one [CasesCubit] so a newly created case shows up immediately.
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CasesCubit>()..getCases(),
      child: const _MainShellView(),
    );
  }
}

class _MainShellView extends StatefulWidget {
  const _MainShellView();

  @override
  State<_MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<_MainShellView> {
  int _index = 0;

  static const _titles = ['الرئيسية', 'الحالات', 'إضافة حالة'];

  void _goTo(int index) => setState(() => _index = index);

  void _onCaseCreated() {
    setState(() => _index = 1);
    context.read<CasesCubit>().getCases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.homeScreen),
      appBar: AppBar(
        title: Text(_titles[_index], style: AppTextStyles.font18MediumText),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            HomeBody(
              onOpenCases: () => _goTo(1),
              onAddCase: () => _goTo(2),
            ),
            const CasesListBody(),
            CaseFormPage(onCreated: _onCaseCreated),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
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
