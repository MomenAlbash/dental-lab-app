import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/laboratories/data/models/create_laboratory_request_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/update_laboratory_request_model.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_form/laboratory_form_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_form/laboratory_form_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit laboratory screen. Pass [initialLaboratory] to open in edit mode.
class LaboratoryFormPage extends StatelessWidget {
  const LaboratoryFormPage({super.key, this.initialLaboratory});

  final LaboratoryModel? initialLaboratory;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LaboratoryFormCubit>(),
      child: _LaboratoryFormView(initialLaboratory: initialLaboratory),
    );
  }
}

class _LaboratoryFormView extends StatefulWidget {
  const _LaboratoryFormView({this.initialLaboratory});

  final LaboratoryModel? initialLaboratory;

  @override
  State<_LaboratoryFormView> createState() => _LaboratoryFormViewState();
}

class _LaboratoryFormViewState extends State<_LaboratoryFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialLaboratory?.name ?? '',
  );
  late final _addressController = TextEditingController(
    text: widget.initialLaboratory?.address ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.initialLaboratory?.phoneNumber ?? '',
  );

  late bool _isActive = widget.initialLaboratory?.isActive ?? true;

  bool get _isEditing => widget.initialLaboratory != null;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Optional fields are sent as `null` rather than an empty string so the
  /// API stores "not set" instead of a blank value.
  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<LaboratoryFormCubit>();

    if (_isEditing) {
      cubit.updateLaboratory(
        id: widget.initialLaboratory!.id,
        updateLaboratoryRequestBody: UpdateLaboratoryRequestModel(
          name: _nameController.text.trim(),
          address: _optional(_addressController),
          phoneNumber: _optional(_phoneController),
          isActive: _isActive,
        ),
      );
    } else {
      cubit.createLaboratory(
        CreateLaboratoryRequestModel(
          name: _nameController.text.trim(),
          address: _optional(_addressController),
          phoneNumber: _optional(_phoneController),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          _isEditing ? 'تعديل المخبر' : 'إضافة مخبر',
          style: AppTextStyles.font18MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<LaboratoryFormCubit, LaboratoryFormState>(
          listener: (context, state) {
            switch (state) {
              case LaboratoryFormSuccess():
                ShowToast(
                  message: _isEditing ? 'تم حفظ التعديلات' : 'تمت إضافة المخبر',
                  state: toastState.success,
                );
                Navigator.of(context).pop(true);
              case LaboratoryFormError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          builder: (context, state) {
            final isSubmitting = state is LaboratoryFormSubmitting;

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
                            Text(
                              'اسم المخبر',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            AppTextFormField(
                              controller: _nameController,
                              hintText: 'أدخل اسم المخبر',
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icon(
                                Icons.science_outlined,
                                color: context.glass.onGlassMuted,
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'اسم المخبر مطلوب'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'العنوان',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            AppTextFormField(
                              controller: _addressController,
                              hintText: 'أدخل العنوان (اختياري)',
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: context.glass.onGlassMuted,
                              ),
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'رقم الهاتف',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            AppTextFormField(
                              controller: _phoneController,
                              hintText: 'أدخل رقم الهاتف (اختياري)',
                              textInputAction: TextInputAction.done,
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: context.glass.onGlassMuted,
                              ),
                              validator: (_) => null,
                            ),
                            if (_isEditing) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: context.glass.surfaceGradient,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.glass,
                                  ),
                                  border: Border.all(
                                    color: context.glass.strokeColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'مفعّل',
                                        style: AppTextStyles.font14MediumText,
                                      ),
                                    ),
                                    Switch(
                                      value: _isActive,
                                      activeThumbColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      onChanged: (value) =>
                                          setState(() => _isActive = value),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            if (isSubmitting)
                              const Center(
                                child: CustomCircleProgressIndiacatorWidget(),
                              )
                            else
                              CustomButtonWidget(
                                onPressed: _onSavePressed,
                                buttonText: _isEditing
                                    ? 'حفظ التعديلات'
                                    : 'إضافة المخبر',
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
