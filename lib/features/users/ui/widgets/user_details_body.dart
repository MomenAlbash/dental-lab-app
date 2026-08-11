import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/widgets/adaptive_detail_sections.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_cubit.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_state.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/ui/widgets/labeled_dropdown.dart';
import 'package:dental_lab_app/features/users/ui/widgets/user_hero_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The user details section: a collapsing identity header (mirrors the
/// doctor/employee detail screens), linked record + role, the editable
/// fields (email, role, admin) and account actions.
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
        Builder(
          builder: (context) {
            return CustomScrollView(
              slivers: [
                UserSliverHeader(user: user),
                SliverToBoxAdapter(
                  child: AdaptiveDetailSections(
                    // The edit form is the screen's real work, so it takes the
                    // wide column; the read-only summary and the account
                    // actions sit beside it.
                    main: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const GlassSectionTitle('تعديل البيانات'),
                          const SizedBox(height: 12),
                          const _Label('البريد الإلكتروني'),
                          AppTextFormField(
                            controller: emailController,
                            hintText: 'أدخل البريد الإلكتروني',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: context.glass.onGlassMuted,
                            ),
                            validator: (_) => null,
                          ),
                          const SizedBox(height: 20),
                          const _Label('الدور'),
                          _RoleDropdown(
                            value: roleId,
                            onChanged: onRoleChanged,
                          ),
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
                          ),
                        ],
                      ),
                    ],
                    side: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          gradient: context.glass.surfaceGradient,
                          borderRadius: BorderRadius.circular(AppRadius.glass),
                          border: Border.all(color: context.glass.strokeColor),
                          boxShadow: context.glass.shadows,
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
                            Divider(
                              height: 1,
                              color: context.glass.strokeColor,
                            ),
                            DetailInfoRowWidget(
                              icon: Icons.email_outlined,
                              label: 'البريد الإلكتروني',
                              value: user.email ?? '',
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const GlassSectionTitle('إجراءات الحساب'),
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
                                ? context.glass.error
                                : context.glass.success,
                            backgroundColor:
                                (user.isActive
                                        ? context.glass.error
                                        : context.glass.success)
                                    .withValues(alpha: 0.08),
                          ),
                          const SizedBox(height: 12),
                          // Tonal secondary action: the accent is the
                          // theme's, not a fixed brand constant, so it
                          // follows dark mode too.
                          CustomButtonWidget(
                            onPressed: onResetPassword,
                            icon: Icons.lock_reset_outlined,
                            buttonText: 'إعادة تعيين كلمة المرور',
                            textColor: Theme.of(context).colorScheme.primary,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: context.glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: context.glass.strokeColor),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.font14MediumText)),
          Switch(
            value: value,
            activeThumbColor: Theme.of(context).colorScheme.primary,
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
