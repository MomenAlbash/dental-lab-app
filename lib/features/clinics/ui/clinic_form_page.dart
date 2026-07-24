import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';

// Mock options until the Cities/PriceTiers lookups are wired in from the API.
const List<String> _mockCities = ['دمشق', 'حلب', 'حمص', 'اللاذقية'];
const List<String> _mockPriceTiers = ['قياسي', 'مميز', 'VIP'];

/// Add/edit clinic screen — design only for now (no Cubit / API wiring yet).
/// Pass [initialClinic] to open in edit mode.
class ClinicFormPage extends StatefulWidget {
  const ClinicFormPage({super.key, this.initialClinic});

  final Map<String, dynamic>? initialClinic;

  @override
  State<ClinicFormPage> createState() => _ClinicFormPageState();
}

class _ClinicFormPageState extends State<ClinicFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialClinic?['name'] as String? ?? '',
  );
  late final _addressController = TextEditingController(
    text: widget.initialClinic?['address'] as String? ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.initialClinic?['phoneNumber'] as String? ?? '',
  );
  late final _emailController = TextEditingController(
    text: widget.initialClinic?['email'] as String? ?? '',
  );

  late String? _cityName = widget.initialClinic?['cityName'] as String?;
  late String? _priceTierName = widget.initialClinic?['priceTierName'] as String?;
  late bool _isActive = widget.initialClinic?['isActive'] as bool? ?? true;

  bool get _isEditing => widget.initialClinic != null;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط حفظ العيادة بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل العيادة' : 'إضافة عيادة',
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
                        Text('اسم العيادة', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _nameController,
                          hintText: 'أدخل اسم العيادة',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.local_hospital_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'اسم العيادة مطلوب'
                              : null,
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
                        Text('البريد الإلكتروني', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _emailController,
                          hintText: 'أدخل البريد الإلكتروني (اختياري)',
                          textInputAction: TextInputAction.done,
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
                        Text('المدينة', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        _DropdownField(
                          hintText: 'اختر المدينة (اختياري)',
                          icon: Icons.location_city_outlined,
                          value: _cityName,
                          options: _mockCities,
                          onChanged: (value) => setState(() => _cityName = value),
                        ),
                        const SizedBox(height: 20),
                        Text('فئة التسعير', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        _DropdownField(
                          hintText: 'اختر فئة التسعير (اختياري)',
                          icon: Icons.sell_outlined,
                          value: _priceTierName,
                          options: _mockPriceTiers,
                          onChanged: (value) => setState(() => _priceTierName = value),
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
                                  child: Text('مفعّلة', style: AppTextStyles.font14MediumText),
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
                          buttonText: _isEditing ? 'حفظ التعديلات' : 'إضافة العيادة',
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
