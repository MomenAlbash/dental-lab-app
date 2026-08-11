import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_cubit.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/logic/user_details/user_details_cubit.dart';
import 'package:dental_lab_app/features/users/logic/user_details/user_details_state.dart';
import 'package:dental_lab_app/features/users/ui/widgets/user_details_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// User detail screen — view the account, edit email/role/admin, toggle active
/// state and reset the password.
class UserDetailPage extends StatelessWidget {
  const UserDetailPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<UserDetailsCubit>()..getUser(userId)),
        BlocProvider(create: (_) => getIt<RolesCubit>()..getRoles()),
      ],
      child: const _UserDetailView(),
    );
  }
}

class _UserDetailView extends StatefulWidget {
  const _UserDetailView();

  @override
  State<_UserDetailView> createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<_UserDetailView> {
  final _emailController = TextEditingController();
  String? _roleId;
  bool _isAdmin = false;
  bool _initialized = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Seeds the editable fields from the loaded user, once.
  void _initFrom(UserModel user) {
    if (_initialized) return;
    _emailController.text = user.email ?? '';
    _roleId = user.roleId;
    _isAdmin = user.isAdmin;
    _initialized = true;
  }

  void _onSave(UserModel user) {
    context.read<UserDetailsCubit>().saveChanges(
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      roleId: _roleId,
      isAdmin: _isAdmin,
      isActive: user.isActive,
    );
  }

  Future<void> _onResetPassword() async {
    final cubit = context.read<UserDetailsCubit>();
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'إعادة تعيين كلمة المرور',
          style: AppTextStyles.font18MediumText,
        ),
        content: Form(
          key: formKey,
          child: AppTextFormField(
            controller: controller,
            hintText: 'كلمة المرور الجديدة',
            isObscureText: true,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: context.glass.onGlassMuted,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
              return value.length < 4 ? 'كلمة المرور 4 أحرف على الأقل' : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('إلغاء', style: AppTextStyles.font14MediumText),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: Text(
              'تأكيد',
              style: AppTextStyles.font14MediumText.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.resetPassword(controller.text);
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserDetailsCubit, UserDetailsState>(
      listenWhen: (previous, current) =>
          current is UserDetailsActionError ||
          current is UserDetailsActionSuccess,
      listener: (context, state) {
        switch (state) {
          case UserDetailsActionSuccess(:final message):
            ShowToast(message: message, state: toastState.success);
          case UserDetailsActionError(:final message):
            ShowToast(message: message, state: toastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! UserDetailsActionError &&
          current is! UserDetailsActionSuccess,
      builder: (context, state) {
        final user = state is UserDetailsLoaded ? state.user : null;

        // No `appBar` here: once loaded, the body supplies its own collapsing
        // SliverAppBar. A plain glass bar is used only for the loading and
        // error states, which have no header to collapse.
        return GlassScaffold(
          appBar: user != null
              ? null
              : GlassAppBar(
                  title: Text(
                    'تفاصيل المستخدم',
                    style: AppTextStyles.font18MediumText.copyWith(
                      color: context.glass.onGlass,
                    ),
                  ),
                ),
          body: switch (state) {
            UserDetailsLoaded(:final user, :final isBusy) => Builder(
              builder: (context) {
                _initFrom(user);
                return UserDetailsBody(
                  user: user,
                  isBusy: isBusy,
                  emailController: _emailController,
                  roleId: _roleId,
                  onRoleChanged: (value) => setState(() => _roleId = value),
                  isAdmin: _isAdmin,
                  onAdminChanged: (value) => setState(() => _isAdmin = value),
                  onSave: () => _onSave(user),
                  onToggleActive: () =>
                      context.read<UserDetailsCubit>().toggleActive(),
                  onResetPassword: _onResetPassword,
                );
              },
            ),
            UserDetailsError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: context.glass.onGlassMuted,
                  ),
                ),
              ),
            ),
            _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
          },
        );
      },
    );
  }
}
