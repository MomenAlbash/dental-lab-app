import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_state.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_cubit.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_state.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/ui/widgets/labeled_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The create-user form section: account type, the linked doctor/employee
/// picker, credentials, role and the admin flag. State is owned by the page.
class UserFormFields extends StatelessWidget {
  const UserFormFields({
    super.key,
    required this.formKey,
    required this.type,
    required this.onTypeChanged,
    required this.employeeId,
    required this.onEmployeeChanged,
    required this.doctorId,
    required this.onDoctorChanged,
    required this.usernameController,
    required this.passwordController,
    required this.emailController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.roleId,
    required this.onRoleChanged,
    required this.isAdmin,
    required this.onAdminChanged,
    required this.isSubmitting,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final UserType type;
  final ValueChanged<UserType> onTypeChanged;
  final String? employeeId;
  final ValueChanged<String?> onEmployeeChanged;
  final String? doctorId;
  final ValueChanged<String?> onDoctorChanged;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController emailController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final String? roleId;
  final ValueChanged<String?> onRoleChanged;
  final bool isAdmin;
  final ValueChanged<bool> onAdminChanged;
  final bool isSubmitting;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Label('نوع المستخدم'),
          SegmentedButton<UserType>(
            segments: const [
              ButtonSegment(value: UserType.employee, label: Text('موظف')),
              ButtonSegment(value: UserType.doctor, label: Text('طبيب')),
            ],
            selected: {type},
            onSelectionChanged: (selection) => onTypeChanged(selection.first),
          ),
          const SizedBox(height: 20),
          if (type == UserType.employee) ...[
            const _Label('الموظف'),
            _EmployeeDropdown(value: employeeId, onChanged: onEmployeeChanged),
          ] else ...[
            const _Label('الطبيب'),
            _DoctorDropdown(value: doctorId, onChanged: onDoctorChanged),
          ],
          const SizedBox(height: 20),
          const _Label('اسم المستخدم'),
          AppTextFormField(
            controller: usernameController,
            hintText: 'أدخل اسم المستخدم',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(
              Icons.person_outline,
              color: context.glass.onGlassMuted,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'اسم المستخدم مطلوب'
                : null,
          ),
          const SizedBox(height: 20),
          const _Label('كلمة المرور'),
          AppTextFormField(
            controller: passwordController,
            hintText: 'أدخل كلمة المرور',
            textInputAction: TextInputAction.next,
            isObscureText: obscurePassword,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: context.glass.onGlassMuted,
            ),
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: context.glass.onGlassMuted,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
              return value.length < 4 ? 'كلمة المرور 4 أحرف على الأقل' : null;
            },
          ),
          const SizedBox(height: 20),
          const _Label('البريد الإلكتروني'),
          AppTextFormField(
            controller: emailController,
            hintText: 'أدخل البريد الإلكتروني (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(
              Icons.email_outlined,
              color: context.glass.onGlassMuted,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              return value.contains('@') ? null : 'بريد إلكتروني غير صالح';
            },
          ),
          const SizedBox(height: 20),
          const _Label('الدور'),
          _RoleDropdown(value: roleId, onChanged: onRoleChanged),
          const SizedBox(height: 20),
          _AdminSwitch(value: isAdmin, onChanged: onAdminChanged),
          const SizedBox(height: 24),
          if (isSubmitting)
            const Center(child: CustomCircleProgressIndiacatorWidget())
          else
            CustomButtonWidget(onPressed: onSave, buttonText: 'إضافة المستخدم'),
        ],
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
      child: Text(text, style: AppTextStyles.font14MediumText),
    );
  }
}

class _AdminSwitch extends StatelessWidget {
  const _AdminSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.glass.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.glass.strokeColor),
      ),
      child: Row(
        children: [
          Expanded(child: Text('مدير', style: AppTextStyles.font14MediumText)),
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

class _EmployeeDropdown extends StatelessWidget {
  const _EmployeeDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeesCubit, EmployeesState>(
      builder: (context, state) {
        final employees = state is EmployeesLoaded ? state.employees : null;
        return LabeledDropdown(
          value: value,
          icon: Icons.badge_outlined,
          hintText: state is EmployeesLoading
              ? 'جارٍ تحميل الموظفين...'
              : 'اختر الموظف',
          items: employees
              ?.map(
                (employee) => DropdownMenuItem(
                  value: employee.id,
                  child: Text(employee.fullName),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}

class _DoctorDropdown extends StatelessWidget {
  const _DoctorDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoctorsCubit, DoctorsState>(
      builder: (context, state) {
        final doctors = state is DoctorsLoaded ? state.doctors : null;
        return LabeledDropdown(
          value: value,
          icon: Icons.medical_services_outlined,
          hintText: state is DoctorsLoading
              ? 'جارٍ تحميل الأطباء...'
              : 'اختر الطبيب',
          items: doctors
              ?.map(
                (doctor) => DropdownMenuItem(
                  value: doctor.id,
                  child: Text(doctor.fullName),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
