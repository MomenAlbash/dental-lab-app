import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/create_price_tier_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/update_price_tier_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_form/price_tier_form_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_form/price_tier_form_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit price-tier screen. Pass [initialPriceTier] to edit.
class PriceTierFormPage extends StatelessWidget {
  const PriceTierFormPage({super.key, this.initialPriceTier});

  final PriceTierModel? initialPriceTier;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PriceTierFormCubit>(),
      child: _PriceTierFormView(initialPriceTier: initialPriceTier),
    );
  }
}

class _PriceTierFormView extends StatefulWidget {
  const _PriceTierFormView({this.initialPriceTier});

  final PriceTierModel? initialPriceTier;

  @override
  State<_PriceTierFormView> createState() => _PriceTierFormViewState();
}

class _PriceTierFormViewState extends State<_PriceTierFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialPriceTier?.name ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.initialPriceTier?.description ?? '',
  );

  late bool _isActive = widget.initialPriceTier?.isActive ?? true;

  bool get _isEditing => widget.initialPriceTier != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<PriceTierFormCubit>();

    if (_isEditing) {
      cubit.updatePriceTier(
        id: widget.initialPriceTier!.id,
        updateRequestBody: UpdatePriceTierRequestModel(
          name: _nameController.text.trim(),
          description: _optional(_descriptionController),
          isActive: _isActive,
        ),
      );
    } else {
      cubit.createPriceTier(
        CreatePriceTierRequestModel(
          name: _nameController.text.trim(),
          description: _optional(_descriptionController),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل الشريحة السعرية' : 'إضافة شريحة سعرية',
          style: AppTextStyles.font18MediumText,
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<PriceTierFormCubit, PriceTierFormState>(
          listener: (context, state) {
            switch (state) {
              case PriceTierFormSuccess():
                ShowToast(
                  message: _isEditing ? 'تم حفظ التعديلات' : 'تمت إضافة الشريحة',
                  state: toastState.success,
                );
                Navigator.of(context).pop(true);
              case PriceTierFormError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          builder: (context, state) {
            return LayoutBuilder(
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
                            const _Label('الاسم'),
                            AppTextFormField(
                              controller: _nameController,
                              hintText: 'أدخل اسم الشريحة السعرية',
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(
                                Icons.sell_outlined,
                                color: AppColorsManger.textSecondary,
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'الاسم مطلوب'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            const _Label('الوصف'),
                            AppTextFormField(
                              controller: _descriptionController,
                              hintText: 'أدخل وصف الشريحة (اختياري)',
                              textInputAction: TextInputAction.done,
                              prefixIcon: const Icon(
                                Icons.notes_outlined,
                                color: AppColorsManger.textSecondary,
                              ),
                              validator: (_) => null,
                            ),
                            if (_isEditing) ...[
                              const SizedBox(height: 20),
                              _SwitchTile(
                                label: 'مفعّلة',
                                value: _isActive,
                                onChanged: (value) =>
                                    setState(() => _isActive = value),
                              ),
                            ],
                            const SizedBox(height: 24),
                            if (state is PriceTierFormSubmitting)
                              const Center(
                                child: CustomCircleProgressIndiacatorWidget(),
                              )
                            else
                              CustomButtonWidget(
                                onPressed: _onSavePressed,
                                buttonText: _isEditing
                                    ? 'حفظ التعديلات'
                                    : 'إضافة الشريحة',
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
            );
          },
        ),
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
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, style: AppTextStyles.font14MediumText),
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
