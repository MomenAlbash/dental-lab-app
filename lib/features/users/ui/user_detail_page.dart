import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:flutter/material.dart';

// Mock options until the Roles/Doctors lookups are wired in from the API.
const List<String> _mockRoles = ['مدير', 'موظف استقبال', 'طبيب'];
const List<String> _mockDoctors = ['أحمد الخطيب', 'سارة يوسف', 'محمد حسن'];

/// User detail screen — design only for now (no Cubit / API wiring yet).
/// Covers everything besides create: view, update (`UpdateUserRequest`:
/// email/role/isAdmin/isActive), activate/deactivate, reset password, and
/// doctor-scope (restricting a staff user to specific doctors' cases).
class UserDetailPage extends StatefulWidget {
  const UserDetailPage({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late final _emailController = TextEditingController(
    text: widget.user['email'] as String? ?? '',
  );

  late String? _roleName = widget.user['roleName'] as String?;
  late bool _isAdmin = widget.user['isAdmin'] as bool;
  late bool _isActive = widget.user['isActive'] as bool;
  late final Set<String> _doctorScope = Set<String>.from(
    (widget.user['doctorScopeIds'] as List<String>?) ?? const [],
  );

  bool get _isDoctorType => widget.user['isDoctorType'] as bool;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSaveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم ربط حفظ التعديلات بالـ API لاحقاً')),
    );
  }

  Future<void> _onToggleActive() async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: _isActive ? 'إيقاف المستخدم' : 'تفعيل المستخدم',
      message: _isActive
          ? 'هل أنت متأكد من إيقاف هذا المستخدم؟'
          : 'هل أنت متأكد من تفعيل هذا المستخدم؟',
      confirmText: _isActive ? 'إيقاف' : 'تفعيل',
      isDestructive: _isActive,
    );

    if (confirmed == true && mounted) {
      setState(() => _isActive = !_isActive);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط هذا الإجراء بالـ API لاحقاً')),
      );
    }
  }

  Future<void> _onResetPassword() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إعادة تعيين كلمة المرور', style: AppTextStyles.font18MediumText),
        content: Form(
          key: formKey,
          child: AppTextFormField(
            controller: controller,
            hintText: 'كلمة المرور الجديدة',
            isObscureText: true,
            prefixIcon: const Icon(Icons.lock_outline, color: AppColorsManger.textSecondary),
            validator: (value) {
              if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
              return value.length < 4 ? 'كلمة المرور 4 أحرف على الأقل' : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('إلغاء', style: AppTextStyles.font14MediumText),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(
              'تأكيد',
              style: AppTextStyles.font14MediumText.copyWith(color: AppColorsManger.primary),
            ),
          ),
        ],
      ),
    );

    controller.dispose();

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط إعادة تعيين كلمة المرور بالـ API لاحقاً')),
      );
    }
  }

  Future<void> _onEditDoctorScope() async {
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _DoctorScopeDialog(initialSelection: _doctorScope),
    );

    if (selected != null && mounted) {
      setState(() {
        _doctorScope
          ..clear()
          ..addAll(selected);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط حفظ تقييد الأطباء بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final linkedName = _isDoctorType
        ? user['doctorName'] as String? ?? ''
        : user['employeeName'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text('تفاصيل المستخدم', style: AppTextStyles.font18MediumText),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
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
                                _isDoctorType
                                    ? Icons.medical_services_outlined
                                    : Icons.badge_outlined,
                                size: 36,
                                color: AppColorsManger.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user['username'] as String,
                              style: AppTextStyles.font20BoldText,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isDoctorType ? 'حساب طبيب' : 'حساب موظف',
                              style: AppTextStyles.font13MediumPrimary,
                            ),
                          ],
                        ),
                      ),
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
                              icon: _isDoctorType
                                  ? Icons.medical_services_outlined
                                  : Icons.badge_outlined,
                              label: _isDoctorType ? 'الطبيب المرتبط' : 'الموظف المرتبط',
                              value: linkedName,
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.security_outlined,
                              label: 'الدور',
                              value: _roleName ?? '',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('تعديل البيانات', style: AppTextStyles.font16MediumText),
                      const SizedBox(height: 12),
                      Text('البريد الإلكتروني', style: AppTextStyles.font14MediumText),
                      const SizedBox(height: 8),
                      AppTextFormField(
                        controller: _emailController,
                        hintText: 'أدخل البريد الإلكتروني',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColorsManger.textSecondary,
                        ),
                        validator: (_) => null,
                      ),
                      const SizedBox(height: 20),
                      Text('الدور', style: AppTextStyles.font14MediumText),
                      const SizedBox(height: 8),
                      _DropdownField(
                        hintText: 'اختر الدور',
                        icon: Icons.security_outlined,
                        value: _roleName,
                        options: _mockRoles,
                        onChanged: (value) => setState(() => _roleName = value),
                      ),
                      const SizedBox(height: 12),
                      _SwitchTile(
                        label: 'مدير',
                        value: _isAdmin,
                        onChanged: (value) => setState(() => _isAdmin = value),
                      ),
                      const SizedBox(height: 24),
                      CustomButtonWidget(
                        onPressed: _onSaveChanges,
                        buttonText: 'حفظ التعديلات',
                        textColor: Colors.white,
                        backgroundColor: AppColorsManger.primary,
                      ),
                      const SizedBox(height: 32),
                      Text('إجراءات الحساب', style: AppTextStyles.font16MediumText),
                      const SizedBox(height: 12),
                      CustomButtonWidget(
                        onPressed: _onToggleActive,
                        icon: _isActive ? Icons.block_outlined : Icons.check_circle_outline,
                        buttonText: _isActive ? 'إيقاف المستخدم' : 'تفعيل المستخدم',
                        textColor: _isActive ? AppColorsManger.error : AppColorsManger.success,
                        backgroundColor: (_isActive ? AppColorsManger.error : AppColorsManger.success)
                            .withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      CustomButtonWidget(
                        onPressed: _onResetPassword,
                        icon: Icons.lock_reset_outlined,
                        buttonText: 'إعادة تعيين كلمة المرور',
                        textColor: AppColorsManger.primary,
                        backgroundColor: AppColorsManger.primarySurface,
                      ),
                      if (!_isDoctorType) ...[
                        const SizedBox(height: 12),
                        CustomButtonWidget(
                          onPressed: _onEditDoctorScope,
                          icon: Icons.medical_services_outlined,
                          buttonText: 'تقييد الأطباء (${_doctorScope.length})',
                          textColor: AppColorsManger.primary,
                          backgroundColor: AppColorsManger.primarySurface,
                        ),
                      ],
                    ],
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

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({required this.label, required this.value, required this.onChanged});

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

class _DoctorScopeDialog extends StatefulWidget {
  const _DoctorScopeDialog({required this.initialSelection});

  final Set<String> initialSelection;

  @override
  State<_DoctorScopeDialog> createState() => _DoctorScopeDialogState();
}

class _DoctorScopeDialogState extends State<_DoctorScopeDialog> {
  late final Set<String> _selected = Set<String>.from(widget.initialSelection);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تقييد الأطباء', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _mockDoctors
              .map(
                (doctor) => CheckboxListTile(
                  value: _selected.contains(doctor),
                  title: Text(doctor, style: AppTextStyles.font14MediumText),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (checked) => setState(() {
                    if (checked ?? false) {
                      _selected.add(doctor);
                    } else {
                      _selected.remove(doctor);
                    }
                  }),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('إلغاء', style: AppTextStyles.font14MediumText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(
            'حفظ',
            style: AppTextStyles.font14MediumText.copyWith(color: AppColorsManger.primary),
          ),
        ),
      ],
    );
  }
}
