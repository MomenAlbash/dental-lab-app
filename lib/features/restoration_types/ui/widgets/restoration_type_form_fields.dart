import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/create_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/update_restoration_type_request_model.dart';
import 'package:flutter/material.dart';

/// The restoration-type add/edit form section. State is owned by the page.
class RestorationTypeFormFields extends StatelessWidget {
  const RestorationTypeFormFields({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.nameArController,
    required this.descriptionController,
    required this.defaultPriceController,
    required this.transparencyController,
    required this.lowDurationController,
    required this.normalDurationController,
    required this.highDurationController,
    required this.urgentDurationController,
    required this.pricingType,
    required this.onPricingTypeChanged,
    required this.isEditing,
    required this.isActive,
    required this.onActiveChanged,
    required this.stages,
    required this.onAddStage,
    required this.onRemoveStage,
    required this.onToggleStageFinal,
    this.editStages = const [],
    this.onAddEditStage,
    this.onRemoveEditStage,
    this.onToggleEditStageFinal,
    required this.isSubmitting,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController nameArController;
  final TextEditingController descriptionController;
  final TextEditingController defaultPriceController;
  final TextEditingController transparencyController;
  final TextEditingController lowDurationController;
  final TextEditingController normalDurationController;
  final TextEditingController highDurationController;
  final TextEditingController urgentDurationController;
  final int pricingType;
  final ValueChanged<int> onPricingTypeChanged;
  final bool isEditing;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;

  /// Workflow stages this restoration type moves through, in order. Only
  /// editable while creating — the API takes them inline on create.
  final List<CreateRestorationTypeStageRequestModel> stages;
  final VoidCallback onAddStage;
  final ValueChanged<int> onRemoveStage;
  final ValueChanged<int> onToggleStageFinal;

  /// Stages for the type being edited. Sent as a full replace with the
  /// update request when "save" is pressed.
  final List<UpdateRestorationTypeStageRequestModel> editStages;
  final VoidCallback? onAddEditStage;
  final ValueChanged<int>? onRemoveEditStage;
  final ValueChanged<int>? onToggleEditStageFinal;

  final bool isSubmitting;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Label('الاسم'),
          AppTextFormField(
            controller: nameController,
            hintText: 'أدخل اسم التعويض',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.category_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'الاسم مطلوب'
                : null,
          ),
          const SizedBox(height: 20),
          const _Label('الاسم بالعربية'),
          AppTextFormField(
            controller: nameArController,
            hintText: 'أدخل الاسم بالعربية (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.translate_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (_) => null,
          ),
          const SizedBox(height: 20),
          const _Label('الوصف'),
          AppTextFormField(
            controller: descriptionController,
            hintText: 'أدخل وصف التعويض (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.notes_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (_) => null,
          ),
          const SizedBox(height: 20),
          const _Label('السعر الافتراضي'),
          AppTextFormField(
            controller: defaultPriceController,
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
          const _Label('نسبة الشفافية'),
          AppTextFormField(
            controller: transparencyController,
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
          const _Label('نوع التسعير'),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('ثابت')),
              ButtonSegment(value: 2, label: Text('بالسن')),
              ButtonSegment(value: 3, label: Text('بالوحدة')),
            ],
            selected: {pricingType},
            onSelectionChanged: (selection) =>
                onPricingTypeChanged(selection.first),
          ),
          const SizedBox(height: 24),
          _SectionTitle('مدة الإنجاز حسب الأولوية (بالدقائق)'),
          const SizedBox(height: 12),
          _DurationField(
            label: 'منخفضة',
            controller: lowDurationController,
          ),
          const SizedBox(height: 12),
          _DurationField(
            label: 'عادية',
            controller: normalDurationController,
          ),
          const SizedBox(height: 12),
          _DurationField(
            label: 'عالية',
            controller: highDurationController,
          ),
          const SizedBox(height: 12),
          _DurationField(
            label: 'عاجلة',
            controller: urgentDurationController,
          ),
          const SizedBox(height: 24),
          if (!isEditing) ...[
            _SectionTitle('مراحل العمل'),
            const SizedBox(height: 4),
            Text(
              'المراحل التي يمر بها هذا التعويض داخل المخبر، بالترتيب.',
              style: AppTextStyles.font12RegularHint,
            ),
            const SizedBox(height: 12),
            _StagesEditor(
              stages: stages,
              onAdd: onAddStage,
              onRemove: onRemoveStage,
              onToggleFinal: onToggleStageFinal,
            ),
            const SizedBox(height: 24),
          ],
          if (isEditing) ...[
            _SectionTitle('مراحل العمل'),
            const SizedBox(height: 4),
            Text(
              'المراحل التي يمر بها هذا التعويض داخل المخبر، بالترتيب.',
              style: AppTextStyles.font12RegularHint,
            ),
            const SizedBox(height: 12),
            _EditStagesEditor(
              stages: editStages,
              onAdd: onAddEditStage,
              onRemove: onRemoveEditStage,
              onToggleFinal: onToggleEditStageFinal,
            ),
            const SizedBox(height: 24),
          ],
          if (isEditing) ...[
            _SwitchTile(
              label: 'مفعّل',
              value: isActive,
              onChanged: onActiveChanged,
            ),
            const SizedBox(height: 24),
          ],
          if (isSubmitting)
            const Center(child: CustomCircleProgressIndiacatorWidget())
          else
            CustomButtonWidget(
              onPressed: onSave,
              buttonText: isEditing ? 'حفظ التعديلات' : 'إضافة التعويض',
              textColor: Colors.white,
              backgroundColor: AppColorsManger.primary,
            ),
        ],
      ),
    );
  }
}

/// The ordered list of workflow stages, with add/remove and a "final stage"
/// toggle per row.
class _StagesEditor extends StatelessWidget {
  const _StagesEditor({
    required this.stages,
    required this.onAdd,
    required this.onRemove,
    required this.onToggleFinal,
  });

  final List<CreateRestorationTypeStageRequestModel> stages;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onToggleFinal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'لم تتم إضافة مراحل',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary,
            ),
          )
        else
          ...stages.asMap().entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColorsManger.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColorsManger.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColorsManger.primarySurface,
                    child: Text(
                      '${entry.key + 1}',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: AppColorsManger.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value.name,
                      style: AppTextStyles.font14MediumText,
                    ),
                  ),
                  Tooltip(
                    message: entry.value.isFinal
                        ? 'مرحلة نهائية'
                        : 'تعيين كمرحلة نهائية',
                    child: IconButton(
                      onPressed: () => onToggleFinal(entry.key),
                      icon: Icon(
                        entry.value.isFinal
                            ? Icons.flag
                            : Icons.outlined_flag,
                        color: entry.value.isFinal
                            ? AppColorsManger.success
                            : AppColorsManger.textHint,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemove(entry.key),
                    icon: const Icon(
                      Icons.close,
                      color: AppColorsManger.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('إضافة مرحلة'),
        ),
      ],
    );
  }
}

/// The ordered list of stages on the type being edited, with add/remove and
/// a "final stage" toggle per row. Sent as a full replace on save.
class _EditStagesEditor extends StatelessWidget {
  const _EditStagesEditor({
    required this.stages,
    required this.onAdd,
    required this.onRemove,
    required this.onToggleFinal,
  });

  final List<UpdateRestorationTypeStageRequestModel> stages;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onRemove;
  final ValueChanged<int>? onToggleFinal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'لم تتم إضافة مراحل',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary,
            ),
          )
        else
          ...stages.asMap().entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColorsManger.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColorsManger.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColorsManger.primarySurface,
                    child: Text(
                      '${entry.key + 1}',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: AppColorsManger.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value.name,
                      style: AppTextStyles.font14MediumText,
                    ),
                  ),
                  Tooltip(
                    message: entry.value.isFinal
                        ? 'مرحلة نهائية'
                        : 'تعيين كمرحلة نهائية',
                    child: IconButton(
                      onPressed: onToggleFinal == null
                          ? null
                          : () => onToggleFinal!(entry.key),
                      icon: Icon(
                        entry.value.isFinal
                            ? Icons.flag
                            : Icons.outlined_flag,
                        color: entry.value.isFinal
                            ? AppColorsManger.success
                            : AppColorsManger.textHint,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove == null ? null : () => onRemove!(entry.key),
                    icon: const Icon(
                      Icons.close,
                      color: AppColorsManger.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('إضافة مرحلة'),
        ),
      ],
    );
  }
}

class _DurationField extends StatelessWidget {
  const _DurationField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: AppTextStyles.font14MediumText),
        ),
        Expanded(
          child: AppTextFormField(
            controller: controller,
            hintText: 'المدة بالدقائق (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.timer_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              return int.tryParse(value) == null
                  ? 'الرجاء إدخال رقم صحيح'
                  : null;
            },
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(text, style: AppTextStyles.font16MediumText),
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
