import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_cubit.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_state.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/ui/widgets/labeled_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The user details section: identity header, linked record + role, the
/// editable fields (email, role, admin) and account actions.
class UserDetailsBody extends StatelessWidget {
  const UserDetailsBody({
    super.key,
    required this.user,
    required this.isBusy,
    required this.emailController,
    required this.roleId,
    required this.onRoleChanged,
    required this.isAdmin,
    required this.onAdminChanged,
    required this.onSave,
    required this.onToggleActive,
    required this.onResetPassword,
  });

  final UserModel user;
  final bool isBusy;
  final TextEditingController emailController;
  final String? roleId;
  final ValueChanged<String?> onRoleChanged;
  final bool isAdmin;
  final ValueChanged<bool> onAdminChanged;
  final VoidCallback onSave;
  final VoidCallback onToggleActive;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    final isDoctor = user.type.isDoctor;

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 560.0 : constraints.maxWidth;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 20,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(user: user),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColorsManger.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColorsManger.border),
                        ),
                        child: Column(
                          children: [
                            DetailInfoRowWidget(
                              icon: isDoctor
                                  ? Icons.medical_services_outlined
                                  : Icons.badge_outlined,
                              label: isDoctor
                                  ? 'الطبيب المرتبط'
                                  : 'الموظف المرتبط',
                              value: user.linkedName,
                            ),
                            const Divider(
                              height: 1,
                              color: AppColorsManger.divider,
                            ),
                            DetailInfoRowWidget(
                              icon: Icons.email_outlined,
                              label: 'البريد الإلكتروني',
                              value: user.email ?? '',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('تعديل البيانات', style: AppTextStyles.font16MediumText),
                      const SizedBox(height: 12),
                      const _Label('البريد الإلكتروني'),
                      AppTextFormField(
                        controller: emailController,
                        hintText: 'أدخل البريد الإلكتروني',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColorsManger.textSecondary,
                        ),
                        validator: (_) => null,
                      ),
                      const SizedBox(height: 20),
                      const _Label('الدور'),
                      _RoleDropdown(value: roleId, onChanged: onRoleChanged),
                      const SizedBox(height: 12),
                      _SwitchTile(
                        label: 'مدير',
                        value: isAdmin,
                        onChanged: onAdminChanged,
                      ),
                      const SizedBox(height: 24),
                      CustomButtonWidget(
                        onPressed: onSave,
                        buttonText: 'حفظ التعديلات',
                        textColor: Colors.white,
                        backgroundColor: AppColorsManger.primary,
                      ),
                      const SizedBox(height: 32),
                      Text('إجراءات الحساب', style: AppTextStyles.font16MediumText),
                      const SizedBox(height: 12),
                      CustomButtonWidget(
                        onPressed: onToggleActive,
                        icon: user.isActive
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
                        buttonText: user.isActive
                            ? 'إيقاف المستخدم'
                            : 'تفعيل المستخدم',
                        textColor: user.isActive
                            ? AppColorsManger.error
                            : AppColorsManger.success,
                        backgroundColor:
                            (user.isActive
                                    ? AppColorsManger.error
                                    : AppColorsManger.success)
                                .withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      CustomButtonWidget(
                        onPressed: onResetPassword,
                        icon: Icons.lock_reset_outlined,
                        buttonText: 'إعادة تعيين كلمة المرور',
                        textColor: AppColorsManger.primary,
                        backgroundColor: AppColorsManger.primarySurface,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (isBusy)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final isDoctor = user.type.isDoctor;
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColorsManger.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDoctor ? Icons.medical_services_outlined : Icons.badge_outlined,
              size: 36,
              color: AppColorsManger.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(user.username ?? '—', style: AppTextStyles.font20BoldText),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isDoctor ? 'حساب طبيب' : 'حساب موظف',
                style: AppTextStyles.font13MediumPrimary,
              ),
              const SizedBox(width: 8),
              _StatusBadge(isActive: user.isActive),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColorsManger.success : AppColorsManger.textHint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'مفعّل' : 'موقوف',
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, style: AppTextStyles.font14MediumText),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColorsManger.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColorsManger.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.font14MediumText)),
          Switch(
            value: value,
            activeThumbColor: AppColorsManger.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RolesCubit, RolesState>(
      builder: (context, state) {
        final roles = state is RolesLoaded ? state.roles : null;
        return LabeledDropdown(
          value: value,
          icon: Icons.security_outlined,
          hintText: state is RolesLoading
              ? 'جارٍ تحميل الأدوار...'
              : 'اختر الدور (اختياري)',
          items: roles
              ?.map(
                (role) => DropdownMenuItem(
                  value: role.id,
                  child: Text(role.name ?? '—'),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
