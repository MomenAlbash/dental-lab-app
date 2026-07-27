import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_state.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employees_list_view.dart';
import 'package:flutter/material.dart';
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.employeesListScreen),
      appBar: AppBar(title: Text('الموظفين', style: AppTextStyles.font18MediumText)),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () async {
            await context.push(Routes.employeeFormScreen);
            if (context.mounted) {
              context.read<EmployeesCubit>().getEmployees();
            }
          },
          backgroundColor: AppColorsManger.primary,
          child: const Icon(Icons.add, color: Colors.white),
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
            return switch (state) {
              EmployeesLoaded(:final employees) => EmployeesListView(
                employees: _filter(employees),
                searchController: _searchController,
                searchQuery: _searchQuery,
                onDelete: _confirmDelete,
              ),
              EmployeesError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary,
                  ),
                ),
              ),
              _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
            };
          },
        ),
      ),
    );
  }
}
