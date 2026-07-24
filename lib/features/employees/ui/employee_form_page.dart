import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';

// Mock options until the Cities lookup is wired in from the API.
const List<String> _mockCities = ['دمشق', 'حلب', 'حمص', 'اللاذقية'];

enum _Gender { male, female }

/// Add/edit employee screen — design only for now (no Cubit / API wiring
/// yet). Pass [initialEmployee] to open in edit mode.
class EmployeeFormPage extends StatefulWidget {
  const EmployeeFormPage({super.key, this.initialEmployee});

  final Map<String, dynamic>? initialEmployee;

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(
    text: widget.initialEmployee?['firstName'] as String? ?? '',
  );
  late final _lastNameController = TextEditingController(
    text: widget.initialEmployee?['lastName'] as String? ?? '',
  );
  late final _nationalNumberController = TextEditingController(
    text: widget.initialEmployee?['nationalNumber'] as String? ?? '',
  );
  late final _codeController = TextEditingController(
    text: widget.initialEmployee?['code'] as String? ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.initialEmployee?['phoneNumber'] as String? ?? '',
  );
  late final _addressController = TextEditingController(
    text: widget.initialEmployee?['address'] as String? ?? '',
  );
  late final _bankNameController = TextEditingController(
    text: widget.initialEmployee?['bankName'] as String? ?? '',
  );
  late final _bankAccountNumberController = TextEditingController(
    text: widget.initialEmployee?['bankAccountNumber'] as String? ?? '',
  );

  _Gender _gender = _Gender.male;
  DateTime? _dateOfBirth;
  String? _cityName;
  late String? _imagePath = widget.initialEmployee?['imagePath'] as String?;

  bool get _isEditing => widget.initialEmployee != null;

  void _onUploadImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم ربط رفع الصورة بالـ API لاحقاً')),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nationalNumberController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1930),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  void _onSavePressed() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (isFormValid && _dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تاريخ الميلاد مطلوب')),
      );
      return;
    }
    if (isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط حفظ الموظف بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل الموظف' : 'إضافة موظف',
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
                        Center(
                          child: GestureDetector(
                            onTap: _onUploadImage,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor: AppColorsManger.primarySurface,
                                  backgroundImage: _imagePath == null
                                      ? null
                                      : NetworkImage(_imagePath!),
                                  child: _imagePath == null
                                      ? const Icon(
                                          Icons.person_outline,
                                          size: 44,
                                          color: AppColorsManger.primary,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColorsManger.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
                        Text('الرقم الوطني', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _nationalNumberController,
                          hintText: 'أدخل الرقم الوطني (اختياري)',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (_) => null,
                        ),
                        const SizedBox(height: 20),
                        Text('رمز الموظف', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _codeController,
                          hintText: 'أدخل رمز الموظف (اختياري)',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.numbers_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (_) => null,
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
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (_) => null,
                        ),
                        const SizedBox(height: 20),
                        Text('اسم البنك', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _bankNameController,
                          hintText: 'أدخل اسم البنك (اختياري)',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.account_balance_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (_) => null,
                        ),
                        const SizedBox(height: 20),
                        Text('رقم الحساب البنكي', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _bankAccountNumberController,
                          hintText: 'أدخل رقم الحساب البنكي (اختياري)',
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.credit_card_outlined,
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
                        Text('المدينة', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        _DropdownField(
                          hintText: 'اختر المدينة (اختياري)',
                          icon: Icons.location_city_outlined,
                          value: _cityName,
                          options: _mockCities,
                          onChanged: (value) => setState(() => _cityName = value),
                        ),
                        const SizedBox(height: 24),
                        CustomButtonWidget(
                          onPressed: _onSavePressed,
                          buttonText: _isEditing ? 'حفظ التعديلات' : 'إضافة الموظف',
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
