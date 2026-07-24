import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';

/// The API's `PricingType` enum (1..3) isn't documented with string labels
/// yet, so it's shown by number until the backend publishes names.
const List<int> _pricingTypes = [1, 2, 3];

/// Add/edit restoration-type screen — design only for now (no Cubit / API
/// wiring yet). Pass [initialRestorationType] to open in edit mode.
class RestorationTypeFormPage extends StatefulWidget {
  const RestorationTypeFormPage({super.key, this.initialRestorationType});

  final Map<String, dynamic>? initialRestorationType;

  @override
  State<RestorationTypeFormPage> createState() =>
      _RestorationTypeFormPageState();
}

class _RestorationTypeFormPageState extends State<RestorationTypeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialRestorationType?['name'] as String? ?? '',
  );
  late final _nameArController = TextEditingController(
    text: widget.initialRestorationType?['nameAr'] as String? ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.initialRestorationType?['description'] as String? ?? '',
  );
  late final _transparencyController = TextEditingController(
    text: widget.initialRestorationType?['transparency']?.toString() ?? '',
  );
  late final _defaultPriceController = TextEditingController(
    text: widget.initialRestorationType?['defaultPrice']?.toString() ?? '',
  );
  late final _displayOrderController = TextEditingController(
    text: widget.initialRestorationType?['displayOrder']?.toString() ?? '',
  );

  int? _pricingType = _pricingTypes.first;
  late bool _showInClinicApp =
      widget.initialRestorationType?['showInClinicApp'] as bool? ?? true;
  late bool _isActive =
      widget.initialRestorationType?['isActive'] as bool? ?? true;

  bool get _isEditing => widget.initialRestorationType != null;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _transparencyController.dispose();
    _defaultPriceController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط حفظ التعويض بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل التعويض' : 'إضافة تعويض',
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
                        Text('الاسم', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _nameController,
                          hintText: 'أدخل اسم التعويض',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'الاسم مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'الاسم بالعربية',
                          style: AppTextStyles.font14MediumText,
                        ),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _nameArController,
                          hintText: 'أدخل الاسم بالعربية (اختياري)',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.translate_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (_) => null,
                        ),
                        const SizedBox(height: 20),
                        Text('الوصف', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _descriptionController,
                          hintText: 'أدخل وصف التعويض (اختياري)',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.notes_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (_) => null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'السعر الافتراضي',
                          style: AppTextStyles.font14MediumText,
                        ),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _defaultPriceController,
                          hintText: 'أدخل السعر الافتراضي',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.attach_money_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'السعر الافتراضي مطلوب';
                            }
                            return double.tryParse(value) == null
                                ? 'الرجاء إدخال رقم صحيح'
                                : null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'نسبة الشفافية',
                          style: AppTextStyles.font14MediumText,
                        ),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _transparencyController,
                          hintText: 'أدخل نسبة الشفافية (اختياري)',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.opacity_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            return double.tryParse(value) == null
                                ? 'الرجاء إدخال رقم صحيح'
                                : null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'ترتيب العرض',
                          style: AppTextStyles.font14MediumText,
                        ),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _displayOrderController,
                          hintText: 'أدخل ترتيب العرض (اختياري)',
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.format_list_numbered,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            return int.tryParse(value) == null
                                ? 'الرجاء إدخال رقم صحيح'
                                : null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'نوع التسعير',
                          style: AppTextStyles.font14MediumText,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<int>(
                          segments: _pricingTypes
                              .map(
                                (type) => ButtonSegment(
                                  value: type,
                                  label: Text('نوع $type'),
                                ),
                              )
                              .toList(),
                          selected: {_pricingType!},
                          onSelectionChanged: (selection) =>
                              setState(() => _pricingType = selection.first),
                        ),
                        const SizedBox(height: 20),
                        _SwitchTile(
                          label: 'إظهار في تطبيق العيادات',
                          value: _showInClinicApp,
                          onChanged: (value) =>
                              setState(() => _showInClinicApp = value),
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 12),
                          _SwitchTile(
                            label: 'مفعّل',
                            value: _isActive,
                            onChanged: (value) =>
                                setState(() => _isActive = value),
                          ),
                        ],
                        const SizedBox(height: 24),
                        CustomButtonWidget(
                          onPressed: _onSavePressed,
                          buttonText: _isEditing
                              ? 'حفظ التعديلات'
                              : 'إضافة التعويض',
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
