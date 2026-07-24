import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';

// Mock options until the Clinics/Cities lookups and Gender labels are wired
// in from the API.
const List<String> _mockClinics = ['عيادة النور', 'عيادة الأمل', 'عيادة الشفاء'];
const List<String> _mockCities = ['دمشق', 'حلب', 'حمص', 'اللاذقية'];

enum _Gender { male, female }

/// Add/edit doctor screen — design only for now (no Cubit / API wiring yet).
/// Pass [initialDoctor] to open in edit mode.
class DoctorFormPage extends StatefulWidget {
  const DoctorFormPage({super.key, this.initialDoctor});

  final Map<String, dynamic>? initialDoctor;

  @override
  State<DoctorFormPage> createState() => _DoctorFormPageState();
}

class _DoctorFormPageState extends State<DoctorFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(
    text: widget.initialDoctor?['firstName'] as String? ?? '',
  );
  late final _lastNameController = TextEditingController(
    text: widget.initialDoctor?['lastName'] as String? ?? '',
  );
  late final _emailController = TextEditingController(
    text: widget.initialDoctor?['email'] as String? ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.initialDoctor?['phoneNumber'] as String? ?? '',
  );
  late final _addressController = TextEditingController(
    text: widget.initialDoctor?['address'] as String? ?? '',
  );

  _Gender _gender = _Gender.male;
  DateTime? _dateOfBirth;
  String? _clinicName;
  String? _cityName;
  late bool _isActive = widget.initialDoctor?['isActive'] as bool? ?? true;

  bool get _isEditing => widget.initialDoctor != null;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(1930),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط حفظ الدكتور بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل الدكتور' : 'إضافة دكتور',
          style: AppTextStyles.font18MediumText,
        ),
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
                        Text('الاسم الأول', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _firstNameController,
                          hintText: 'أدخل الاسم الأول',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'الاسم الأول مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Text('الاسم الأخير', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _lastNameController,
                          hintText: 'أدخل الاسم الأخير',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'الاسم الأخير مطلوب'
                              : null,
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
                        Text('رقم الهاتف', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _phoneController,
                          hintText: 'أدخل رقم الهاتف (اختياري)',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (_) => null,
                        ),
                        const SizedBox(height: 20),
                        Text('العنوان', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _addressController,
                          hintText: 'أدخل العنوان (اختياري)',
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (_) => null,
                        ),
                        const SizedBox(height: 20),
                        Text('الجنس', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        SegmentedButton<_Gender>(
                          segments: const [
                            ButtonSegment(value: _Gender.male, label: Text('ذكر')),
                            ButtonSegment(value: _Gender.female, label: Text('أنثى')),
                          ],
                          selected: {_gender},
                          onSelectionChanged: (selection) =>
                              setState(() => _gender = selection.first),
                        ),
                        const SizedBox(height: 20),
                        Text('تاريخ الميلاد', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        _PickerField(
                          hintText: 'اختر تاريخ الميلاد',
                          icon: Icons.cake_outlined,
                          value: _dateOfBirth == null
                              ? null
                              : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
                          onTap: _pickDateOfBirth,
                        ),
                        const SizedBox(height: 20),
                        Text('العيادة', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        _DropdownField(
                          hintText: 'اختر العيادة (اختياري)',
                          icon: Icons.local_hospital_outlined,
                          value: _clinicName,
                          options: _mockClinics,
                          onChanged: (value) => setState(() => _clinicName = value),
                        ),
                        const SizedBox(height: 20),
                        Text('المدينة', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        _DropdownField(
                          hintText: 'اختر المدينة (اختياري)',
                          icon: Icons.location_city_outlined,
                          value: _cityName,
                          options: _mockCities,
                          onChanged: (value) => setState(() => _cityName = value),
                        ),
                        if (_isEditing) ...[
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
                                  child: Text('نشط', style: AppTextStyles.font14MediumText),
                                ),
                                Switch(
                                  value: _isActive,
                                  activeThumbColor: AppColorsManger.primary,
                                  onChanged: (value) => setState(() => _isActive = value),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        CustomButtonWidget(
                          onPressed: _onSavePressed,
                          buttonText: _isEditing ? 'حفظ التعديلات' : 'إضافة الدكتور',
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

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.hintText,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String hintText;
  final IconData icon;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColorsManger.moreLightGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColorsManger.textSecondary),
            const SizedBox(width: 12),
            Text(
              value ?? hintText,
              style: value == null
                  ? AppTextStyles.font14RegularSecondary
                  : AppTextStyles.font14MediumText,
            ),
          ],
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
