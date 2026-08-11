import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_cubit.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The employees list: search field plus the (locally filtered) list of
/// employees, with pull-to-refresh.
class EmployeesListView extends StatelessWidget {
  const EmployeesListView({
    super.key,
    required this.employees,
    required this.searchController,
    required this.searchQuery,
    required this.onDelete,
    this.scrollController,
  });

  /// Already filtered by the search query.
  final List<EmployeeModel> employees;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<EmployeeModel> onDelete;

  /// Owned by the page, which watches it to collapse the add button.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // The search field keeps a phone-ish inset on a phone and a roomier
        // one from tablet up; the rows are laid out by AdaptiveCollection,
        // which fills the width rather than capping it.
        final horizontal =
            AdaptiveLayout.of(context) == AdaptiveFormFactor.mobile
            ? AppSpacing.lg
            : AppSpacing.xl;

        return Column(
          children: [
            Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    AppSpacing.md,
                    horizontal,
                    AppSpacing.md,
                  ),
                  child: AppTextFormField(
                    controller: searchController,
                    hintText: 'ابحث بالاسم...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'مسح البحث',
                            onPressed: () => searchController.clear(),
                            icon: Icon(
                              Icons.close,
                              color: context.glass.onGlassMuted,
                            ),
                          ),
                    validator: (_) => null,
                  ),
                )
                .animate()
                .fadeIn(duration: AppMotion.base)
                .slideY(
                  begin: -0.12,
                  duration: AppMotion.base,
                  curve: AppMotion.enter,
                ),
            Expanded(
              child: employees.isEmpty
                  ? _EmptyState(searchQuery: searchQuery)
                  : AdaptiveCollection<EmployeeModel>(
                      items: employees,
                      scrollController: scrollController,
                      onRefresh: () =>
                          context.read<EmployeesCubit>().getEmployees(),
                      itemBuilder: (context, employee, _) =>
                          EmployeeListItemWidget(
                            fullName: employee.fullName,
                            initials: employee.initials,
                            code: employee.code ?? '',
                            phoneNumber: employee.phoneNumber ?? '',
                            heroTag: 'employee-avatar-${employee.id}',
                            onTap: () async {
                              await context.push(
                                Routes.employeeDetailScreen,
                                extra: employee.id,
                              );
                              if (context.mounted) {
                                context.read<EmployeesCubit>().getEmployees();
                              }
                            },
                            onEdit: () async {
                              await context.push(
                                Routes.employeeFormScreen,
                                extra: employee,
                              );
                              if (context.mounted) {
                                context.read<EmployeesCubit>().getEmployees();
                              }
                            },
                            onDelete: () => onDelete(employee),
                          ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isSearching = searchQuery.isNotEmpty;

    final (IconData icon, String title, String hint) = isSearching
        ? (Icons.search_off, 'لا توجد نتائج', 'جرّب اسماً آخر أو امسح البحث')
        : (
            Icons.badge_outlined,
            'لا يوجد موظفين بعد',
            'أضف أول موظف بالضغط على زر الإضافة',
          );

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
                  child: Icon(icon, size: 40, color: glass.onGlassMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
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
