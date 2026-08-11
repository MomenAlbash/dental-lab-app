import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
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
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_state.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employees_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class EmployeesListPage extends StatelessWidget {
  const EmployeesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EmployeesCubit>()..getEmployees(),
      child: const _EmployeesListView(),
    );
  }
}

class _EmployeesListView extends StatefulWidget {
  const _EmployeesListView();

  @override
  State<_EmployeesListView> createState() => _EmployeesListViewState();
}

class _EmployeesListViewState extends State<_EmployeesListView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';

  /// Last successfully loaded employees, kept so a refresh can show the
  /// existing rows instead of replacing them with the loading skeleton.
  List<EmployeeModel>? _lastEmployees;

  /// The add button collapses to an icon once the user starts scrolling, so a
  /// wide button never sits on top of the rows they are reading.
  bool _addButtonExtended = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
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
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  List<EmployeeModel> _filter(List<EmployeeModel> employees) {
    if (_searchQuery.isEmpty) return employees;
    final query = _searchQuery.toLowerCase();
    return employees
        .where((employee) => employee.fullName.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _confirmDelete(EmployeeModel employee) async {
    final cubit = context.read<EmployeesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الموظف',
      message: 'هل أنت متأكد من حذف الموظف "${employee.fullName}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteEmployee(employee.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.employeesListScreen),
      appBar: GlassAppBar(
        title: Text(
          'الموظفين',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) =>
            GlassAddButton(
              label: 'إضافة موظف',
              isExtended: _addButtonExtended,
              onPressed: () async {
                await context.push(Routes.employeeFormScreen);
                if (context.mounted) {
                  context.read<EmployeesCubit>().getEmployees();
                }
              },
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            ),
      ),
      body: SafeArea(
        child: BlocConsumer<EmployeesCubit, EmployeesState>(
          listener: (context, state) {
            switch (state) {
              case EmployeeDeleted():
                ShowToast(message: 'تم حذف الموظف', state: toastState.success);
              case EmployeeDeleteError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! EmployeeDeleted && current is! EmployeeDeleteError,
          builder: (context, state) {
            if (state is EmployeesLoaded) _lastEmployees = state.employees;

            // A refresh emits EmployeesLoading. Swapping the list out for the
            // skeleton at that moment unmounts the RefreshIndicator mid-pull,
            // which made pull-to-refresh look like it did nothing. Once we
            // have data, keep showing it and let the indicator run.
            final employees = switch (state) {
              EmployeesLoaded(:final employees) => employees,
              EmployeesLoading() => _lastEmployees,
              _ => null,
            };

            return AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: switch ((state, employees)) {
                (_, final List<EmployeeModel> loaded) => EmployeesListView(
                  key: const ValueKey('employees-loaded'),
                  employees: _filter(loaded),
                  searchController: _searchController,
                  scrollController: _scrollController,
                  searchQuery: _searchQuery,
                  onDelete: _confirmDelete,
                ),
                (EmployeesError(:final message), null) => Center(
                  key: const ValueKey('employees-error'),
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
                  key: ValueKey('employees-loading'),
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
