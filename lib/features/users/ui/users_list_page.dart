import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/features/users/ui/widgets/user_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Users list screen — design only for now (no Cubit / API wiring yet).
/// Each user is either bound to an employee or a doctor record
/// (`UserType`: موظف / طبيب), per `/api/clinic/Users`.
class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  // Placeholder data until the users Cubit/repository are wired in.
  final List<Map<String, dynamic>> _users = [
    {
      'username': 'laila.admin',
      'email': 'laila@example.com',
      'roleName': 'مدير',
      'isDoctorType': false,
      'isActive': true,
      'isAdmin': true,
      'employeeName': 'ليلى حمدان',
      'doctorName': null,
      'doctorScopeIds': <String>[],
    },
    {
      'username': 'dr.ahmad',
      'email': 'ahmad@example.com',
      'roleName': 'طبيب',
      'isDoctorType': true,
      'isActive': true,
      'isAdmin': false,
      'employeeName': null,
      'doctorName': 'أحمد الخطيب',
      'doctorScopeIds': <String>[],
    },
    {
      'username': 'omar.reception',
      'email': '',
      'roleName': 'موظف استقبال',
      'isDoctorType': false,
      'isActive': false,
      'isAdmin': false,
      'employeeName': 'عمر سلامة',
      'doctorName': null,
      'doctorScopeIds': <String>[],
    },
  ];

  Future<void> _confirmDelete(Map<String, dynamic> user) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف المستخدم',
      message: 'هل أنت متأكد من حذف المستخدم "${user['username']}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _users.remove(user));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط الحذف بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.usersListScreen),
      appBar: AppBar(title: Text('المستخدمين', style: AppTextStyles.font18MediumText)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.userFormScreen),
        backgroundColor: AppColorsManger.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 700.0 : constraints.maxWidth;

            if (_users.isEmpty) {
              return Center(
                child: Text('لا يوجد مستخدمين بعد', style: AppTextStyles.font14RegularSecondary),
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
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return UserListItemWidget(
                      username: user['username'] as String,
                      roleName: user['roleName'] as String,
                      isDoctorType: user['isDoctorType'] as bool,
                      isActive: user['isActive'] as bool,
                      isAdmin: user['isAdmin'] as bool,
                      onTap: () => context.push(Routes.userDetailScreen, extra: user),
                      onDelete: () => _confirmDelete(user),
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
