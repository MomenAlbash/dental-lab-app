import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/features/roles/ui/widgets/role_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Roles list screen — design only for now (no Cubit / API wiring yet).
class RolesListPage extends StatefulWidget {
  const RolesListPage({super.key});

  @override
  State<RolesListPage> createState() => _RolesListPageState();
}

class _RolesListPageState extends State<RolesListPage> {
  // Placeholder data until the roles Cubit/repository are wired in.
  final List<Map<String, dynamic>> _roles = [
    {'name': 'مدير', 'description': 'صلاحية كاملة على النظام', 'permissionsCount': 9},
    {'name': 'فني مخبر', 'description': 'إدارة الحالات والمراحل', 'permissionsCount': 4},
    {'name': 'موظف استقبال', 'description': 'إدخال حالات العيادات', 'permissionsCount': 2},
  ];

  Future<void> _confirmDelete(int index) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الدور',
      message: 'هل أنت متأكد من حذف دور "${_roles[index]['name']}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _roles.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط الحذف بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.rolesListScreen),
      appBar: AppBar(title: Text('الأدوار', style: AppTextStyles.font18MediumText)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.roleFormScreen),
        backgroundColor: AppColorsManger.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 700.0 : constraints.maxWidth;

            if (_roles.isEmpty) {
              return Center(
                child: Text('لا يوجد أدوار بعد', style: AppTextStyles.font14RegularSecondary),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 16,
                    vertical: 16,
                  ),
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    return RoleListItemWidget(
                      name: role['name'] as String,
                      description: role['description'] as String,
                      permissionsCount: role['permissionsCount'] as int,
                      onEdit: () => context.push(Routes.roleFormScreen, extra: role),
                      onDelete: () => _confirmDelete(index),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
