import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/logic/users/users_cubit.dart';
import 'package:dental_lab_app/features/users/logic/users/users_state.dart';
import 'package:dental_lab_app/features/users/ui/widgets/users_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UsersListPage extends StatelessWidget {
  const UsersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UsersCubit>()..getUsers(),
      child: const _UsersListView(),
    );
  }
}

class _UsersListView extends StatelessWidget {
  const _UsersListView();

  Future<void> _confirmDelete(BuildContext context, UserModel user) async {
    final cubit = context.read<UsersCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف المستخدم',
      message: 'هل أنت متأكد من حذف المستخدم "${user.username ?? ''}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteUser(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.usersListScreen),
      appBar: AppBar(
        title: Text('المستخدمين', style: AppTextStyles.font18MediumText),
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () async {
            await context.push(Routes.userFormScreen);
            if (context.mounted) {
              context.read<UsersCubit>().getUsers();
            }
          },
          backgroundColor: AppColorsManger.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<UsersCubit, UsersState>(
          listener: (context, state) {
            switch (state) {
              case UserDeleted():
                ShowToast(message: 'تم حذف المستخدم', state: toastState.success);
              case UserDeleteError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! UserDeleted && current is! UserDeleteError,
          builder: (context, state) {
            return switch (state) {
              UsersLoaded(:final users) => UsersListView(
                users: users,
                onDelete: (user) => _confirmDelete(context, user),
              ),
              UsersError(:final message) => Center(
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
