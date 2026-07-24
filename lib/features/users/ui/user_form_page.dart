import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';

// Mock options until Roles/Employees/Doctors lookups are wired in from the API.
const List<String> _mockRoles = ['مدير', 'موظف استقبال', 'طبيب'];
const List<String> _mockEmployees = ['ليلى حمدان', 'عمر سلامة', 'رنا دياب'];
const List<String> _mockDoctors = ['أحمد الخطيب', 'سارة يوسف', 'محمد حسن'];

/// `UserType` (0/1 in the API) isn't documented with string labels, but the
/// user-facing distinction is unambiguous: every account is bound to either
/// an employee or a doctor record.
enum _UserType { employee, doctor }

/// Add-user screen — design only for now (no Cubit / API wiring yet).
/// Per `CreateUserRequest`, `type`/`username`/`password`/`employeeId`/
/// `doctorId` are only set at creation — editing a user only allows
/// email/role/isAdmin/isActive (see [UserDetailPage]).
class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  _UserType _userType = _UserType.employee;
  bool _isAdmin = false;
  bool _obscurePassword = true;
  String? _roleName;
  String? _employeeName;
  String? _doctorName;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    final isLinked = _userType == _UserType.employee ? _employeeName != null : _doctorName != null;
    if (!isLinked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _userType == _UserType.employee ? 'الرجاء اختيار الموظف' : 'الرجاء اختيار الطبيب',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم ربط إنشاء المستخدم بالـ API لاحقاً')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text('إضافة مستخدم', style: AppTextStyles.font18MediumText),
      ),
      body: SafeArea(
        child: LayoutBuilder(
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('نوع المستخدم', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        SegmentedButton<_UserType>(
                          segments: const [
                            ButtonSegment(value: _UserType.employee, label: Text('موظف')),
                            ButtonSegment(value: _UserType.doctor, label: Text('طبيب')),
                          ],
                          selected: {_userType},
                          onSelectionChanged: (selection) => setState(() {
                            _userType = selection.first;
                            _employeeName = null;
                            _doctorName = null;
                          }),
                        ),
                        const SizedBox(height: 20),
                        if (_userType == _UserType.employee) ...[
                          Text('الموظف', style: AppTextStyles.font14MediumText),
                          const SizedBox(height: 8),
                          _DropdownField(
                            hintText: 'اختر الموظف',
                            icon: Icons.badge_outlined,
                            value: _employeeName,
                            options: _mockEmployees,
                            onChanged: (value) => setState(() => _employeeName = value),
                          ),
                        ] else ...[
                          Text('الطبيب', style: AppTextStyles.font14MediumText),
                          const SizedBox(height: 8),
                          _DropdownField(
                            hintText: 'اختر الطبيب',
                            icon: Icons.medical_services_outlined,
                            value: _doctorName,
                            options: _mockDoctors,
                            onChanged: (value) => setState(() => _doctorName = value),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text('اسم المستخدم', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _usernameController,
                          hintText: 'أدخل اسم المستخدم',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'اسم المستخدم مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Text('كلمة المرور', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _passwordController,
                          hintText: 'أدخل كلمة المرور',
                          textInputAction: TextInputAction.next,
                          isObscureText: _obscurePassword,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColorsManger.textSecondary,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColorsManger.textSecondary,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
                            return value.length < 4 ? 'كلمة المرور 4 أحرف على الأقل' : null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Text('البريد الإلكتروني', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _emailController,
                          hintText: 'أدخل البريد الإلكتروني (اختياري)',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            return value.contains('@') ? null : 'بريد إلكتروني غير صالح';
                          },
                        ),
                        const SizedBox(height: 20),
                        Text('الدور', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        _DropdownField(
                          hintText: 'اختر الدور (اختياري)',
                          icon: Icons.security_outlined,
                          value: _roleName,
                          options: _mockRoles,
                          onChanged: (value) => setState(() => _roleName = value),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColorsManger.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColorsManger.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('مدير', style: AppTextStyles.font14MediumText),
                              ),
                              Switch(
                                value: _isAdmin,
                                activeThumbColor: AppColorsManger.primary,
                                onChanged: (value) => setState(() => _isAdmin = value),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomButtonWidget(
                          onPressed: _onSavePressed,
                          buttonText: 'إضافة المستخدم',
                          textColor: Colors.white,
                          backgroundColor: AppColorsManger.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.hintText,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String hintText;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColorsManger.moreLightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(border: InputBorder.none),
          hint: Row(
            children: [
              Icon(icon, color: AppColorsManger.textSecondary),
              const SizedBox(width: 12),
              Text(hintText, style: AppTextStyles.font14RegularSecondary),
            ],
          ),
          items: options
              .map((option) => DropdownMenuItem(value: option, child: Text(option)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
