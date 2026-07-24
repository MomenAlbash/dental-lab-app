import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';

/// Add/edit laboratory screen — design only for now (no Cubit / API wiring
/// yet). Pass [initialLaboratory] to open in edit mode.
class LaboratoryFormPage extends StatefulWidget {
  const LaboratoryFormPage({super.key, this.initialLaboratory});

  final Map<String, dynamic>? initialLaboratory;

  @override
  State<LaboratoryFormPage> createState() => _LaboratoryFormPageState();
}

class _LaboratoryFormPageState extends State<LaboratoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialLaboratory?['name'] as String? ?? '',
  );
  late final _addressController = TextEditingController(
    text: widget.initialLaboratory?['address'] as String? ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.initialLaboratory?['phoneNumber'] as String? ?? '',
  );

  late bool _isActive = widget.initialLaboratory?['isActive'] as bool? ?? true;

  bool get _isEditing => widget.initialLaboratory != null;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط حفظ المخبر بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل المخبر' : 'إضافة مخبر',
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
                        Text('اسم المخبر', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _nameController,
                          hintText: 'أدخل اسم المخبر',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.science_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'اسم المخبر مطلوب'
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
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (_) => null,
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
                                  child: Text('مفعّل', style: AppTextStyles.font14MediumText),
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
                          buttonText: _isEditing ? 'حفظ التعديلات' : 'إضافة المخبر',
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
