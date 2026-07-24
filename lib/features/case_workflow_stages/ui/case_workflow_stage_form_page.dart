import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';

/// Add/edit case-workflow-stage screen — design only for now (no Cubit / API
/// wiring yet). Pass [initialStage] to open in edit mode.
class CaseWorkflowStageFormPage extends StatefulWidget {
  const CaseWorkflowStageFormPage({super.key, this.initialStage});

  final Map<String, dynamic>? initialStage;

  @override
  State<CaseWorkflowStageFormPage> createState() => _CaseWorkflowStageFormPageState();
}

class _CaseWorkflowStageFormPageState extends State<CaseWorkflowStageFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialStage?['name'] as String? ?? '',
  );
  late final _orderController = TextEditingController(
    text: widget.initialStage?['order']?.toString() ?? '',
  );

  late bool _isActive = widget.initialStage?['isActive'] as bool? ?? true;
  late bool _isFinal = widget.initialStage?['isFinal'] as bool? ?? false;

  bool get _isEditing => widget.initialStage != null;

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط حفظ المرحلة بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل المرحلة' : 'إضافة مرحلة',
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
                        Text('اسم المرحلة', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _nameController,
                          hintText: 'مثال: التصميم، الطحن...',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.timeline_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'اسم المرحلة مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Text('ترتيب المرحلة', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _orderController,
                          hintText: 'أدخل رقم ترتيب المرحلة',
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.format_list_numbered,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'ترتيب المرحلة مطلوب';
                            }
                            return int.tryParse(value) == null ? 'الرجاء إدخال رقم صحيح' : null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _SwitchTile(
                          label: 'مرحلة نهائية',
                          value: _isFinal,
                          onChanged: (value) => setState(() => _isFinal = value),
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 12),
                          _SwitchTile(
                            label: 'مفعّلة',
                            value: _isActive,
                            onChanged: (value) => setState(() => _isActive = value),
                          ),
                        ],
                        const SizedBox(height: 24),
                        CustomButtonWidget(
                          onPressed: _onSavePressed,
                          buttonText: _isEditing ? 'حفظ التعديلات' : 'إضافة المرحلة',
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
