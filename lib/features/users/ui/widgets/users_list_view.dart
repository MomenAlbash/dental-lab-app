import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/logic/users/users_cubit.dart';
import 'package:dental_lab_app/features/users/ui/widgets/user_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The users list section: the list of users with pull-to-refresh.
class UsersListView extends StatelessWidget {
  const UsersListView({super.key, required this.users, required this.onDelete});

  final List<UserModel> users;
  final ValueChanged<UserModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final contentWidth = isWide ? 700.0 : constraints.maxWidth;

        if (users.isEmpty) {
          return Center(
            child: Text(
              'لا يوجد مستخدمين بعد',
              style: AppTextStyles.font14RegularSecondary,
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: RefreshIndicator(
              onRefresh: () => context.read<UsersCubit>().getUsers(),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: 16,
                ),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return UserListItemWidget(
                    username: user.username ?? '—',
                    roleName: user.roleName ?? '',
                    isDoctorType: user.type.isDoctor,
                    isActive: user.isActive,
                    isAdmin: user.isAdmin,
                    onTap: () async {
                      await context.push(
                        Routes.userDetailScreen,
                        extra: user.id,
                      );
                      if (context.mounted) {
                        context.read<UsersCubit>().getUsers();
                      }
                    },
                    onDelete: () => onDelete(user),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
