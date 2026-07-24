import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';

/// Add/edit currency screen — design only for now (no Cubit / API wiring
/// yet). Pass [initialCurrency] to open in edit mode.
class CurrencyFormPage extends StatefulWidget {
  const CurrencyFormPage({super.key, this.initialCurrency});

  final Map<String, dynamic>? initialCurrency;

  @override
  State<CurrencyFormPage> createState() => _CurrencyFormPageState();
}

class _CurrencyFormPageState extends State<CurrencyFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialCurrency?['name'] as String? ?? '',
  );
  late final _codeController = TextEditingController(
    text: widget.initialCurrency?['code'] as String? ?? '',
  );
  late final _symbolController = TextEditingController(
    text: widget.initialCurrency?['symbol'] as String? ?? '',
  );

  bool get _isEditing => widget.initialCurrency != null;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط حفظ العملة بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل العملة' : 'إضافة عملة',
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
                        Text('اسم العملة', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _nameController,
                          hintText: 'مثال: ليرة سورية',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.attach_money_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'اسم العملة مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Text('الرمز الدولي (الكود)', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _codeController,
                          hintText: 'مثال: SYP',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.tag_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'الكود مطلوب';
                            return value.trim().length > 10 ? 'الكود 10 أحرف كحد أقصى' : null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Text('رمز العملة', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _symbolController,
                          hintText: 'مثال: ل.س (اختياري)',
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.currency_exchange_outlined,
                            color: AppColorsManger.textSecondary,
                          ),
                          validator: (_) => null,
                        ),
                        const SizedBox(height: 24),
                        CustomButtonWidget(
                          onPressed: _onSavePressed,
                          buttonText: _isEditing ? 'حفظ التعديلات' : 'إضافة العملة',
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
