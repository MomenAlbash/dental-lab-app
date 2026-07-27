import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_cubit.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The employees list section: search field plus the (locally filtered) list
/// of employees, with pull-to-refresh.
class EmployeesListView extends StatelessWidget {
  const EmployeesListView({
    super.key,
    required this.employees,
    required this.searchController,
    required this.searchQuery,
    required this.onDelete,
  });

  final List<EmployeeModel> employees;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<EmployeeModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final contentWidth = isWide ? 700.0 : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 16,
                    vertical: 16,
                  ),
                  child: AppTextFormField(
                    controller: searchController,
                    hintText: 'ابحث بالاسم...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColorsManger.textSecondary,
                    ),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => searchController.clear(),
                            icon: const Icon(
                              Icons.close,
                              color: AppColorsManger.textSecondary,
                            ),
                          ),
                    validator: (_) => null,
                  ),
                ),
                Expanded(
                  child: employees.isEmpty
                      ? Center(
                          child: Text(
                            searchQuery.isEmpty
                                ? 'لا يوجد موظفين بعد'
                                : 'لا توجد نتائج',
                            style: AppTextStyles.font14RegularSecondary,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<EmployeesCubit>().getEmployees(),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 32 : 16,
                            ),
                            itemCount: employees.length,
                            itemBuilder: (context, index) {
                              final employee = employees[index];
                              return EmployeeListItemWidget(
                                fullName: employee.fullName,
                                code: employee.code ?? '',
                                phoneNumber: employee.phoneNumber ?? '',
                                onTap: () => context.push(
                                  Routes.employeeDetailScreen,
                                  extra: employee.id,
                                ),
                                onEdit: () async {
                                  await context.push(
                                    Routes.employeeFormScreen,
                                    extra: employee,
                                  );
                                  if (context.mounted) {
                                    context
                                        .read<EmployeesCubit>()
                                        .getEmployees();
                                  }
                                },
                                onDelete: () => onDelete(employee),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
