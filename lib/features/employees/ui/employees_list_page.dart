import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Employees list screen — design only for now (no Cubit / API wiring yet).
/// Supports filtering the list by name (mirrors the API's `search` query
/// param, applied locally for now).
class EmployeesListPage extends StatefulWidget {
  const EmployeesListPage({super.key});

  @override
  State<EmployeesListPage> createState() => _EmployeesListPageState();
}

class _EmployeesListPageState extends State<EmployeesListPage> {
  // Placeholder data until the employees Cubit/repository are wired in.
  final List<Map<String, dynamic>> _employees = [
    {
      'firstName': 'ليلى',
      'lastName': 'حمدان',
      'code': 'EMP-001',
      'nationalNumber': '01234567890',
      'gender': 'أنثى',
      'dateOfBirth': '1995-03-12',
      'cityName': 'دمشق',
      'phoneNumber': '0991112233',
      'address': 'المزة، دمشق',
      'bankName': 'بنك سورية والمهجر',
      'bankAccountNumber': '123456789',
      'imagePath': null,
      'files': <Map<String, String>>[
        {'fileName': 'الهوية الشخصية.pdf'},
      ],
    },
    {
      'firstName': 'عمر',
      'lastName': 'سلامة',
      'code': 'EMP-002',
      'nationalNumber': '09876543210',
      'gender': 'ذكر',
      'dateOfBirth': '1990-07-25',
      'cityName': 'حلب',
      'phoneNumber': '0994445566',
      'address': 'الفرقان، حلب',
      'bankName': '',
      'bankAccountNumber': '',
      'imagePath': null,
      'files': <Map<String, String>>[],
    },
    {
      'firstName': 'رنا',
      'lastName': 'دياب',
      'code': '',
      'nationalNumber': '',
      'gender': 'أنثى',
      'dateOfBirth': '1998-11-02',
      'cityName': '',
      'phoneNumber': '0997778899',
      'address': '',
      'bankName': '',
      'bankAccountNumber': '',
      'imagePath': null,
      'files': <Map<String, String>>[],
    },
  ];

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

  List<Map<String, dynamic>> get _filteredEmployees {
    if (_searchQuery.isEmpty) return _employees;
    final query = _searchQuery.toLowerCase();
    return _employees.where((employee) {
      final fullName = '${employee['firstName']} ${employee['lastName']}'.toLowerCase();
      return fullName.contains(query);
    }).toList();
  }

  Future<void> _confirmDelete(Map<String, dynamic> employee) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الموظف',
      message: 'هل أنت متأكد من حذف الموظف "${employee['firstName']} ${employee['lastName']}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _employees.remove(employee));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط الحذف بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.employeesListScreen),
      appBar: AppBar(title: Text('الموظفين', style: AppTextStyles.font18MediumText)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.employeeFormScreen),
        backgroundColor: AppColorsManger.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 700.0 : constraints.maxWidth;
            final employees = _filteredEmployees;

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
                        controller: _searchController,
                        hintText: 'ابحث بالاسم...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColorsManger.textSecondary,
                        ),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () => _searchController.clear(),
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
                                _searchQuery.isEmpty ? 'لا يوجد موظفين بعد' : 'لا توجد نتائج',
                                style: AppTextStyles.font14RegularSecondary,
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: isWide ? 32 : 16,
                              ),
                              itemCount: employees.length,
                              itemBuilder: (context, index) {
                                final employee = employees[index];
                                return EmployeeListItemWidget(
                                  fullName:
                                      '${employee['firstName']} ${employee['lastName']}',
                                  code: employee['code'] as String,
                                  phoneNumber: employee['phoneNumber'] as String,
                                  onTap: () => context.push(
                                    Routes.employeeDetailScreen,
                                    extra: employee,
                                  ),
                                  onEdit: () => context.push(
                                    Routes.employeeFormScreen,
                                    extra: employee,
                                  ),
                                  onDelete: () => _confirmDelete(employee),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
