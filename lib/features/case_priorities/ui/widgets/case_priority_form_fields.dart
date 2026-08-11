import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/badge_variant.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';

/// The badge colours the API accepts, paired with the Arabic label shown in
/// the picker. Kept here rather than in the model: these are the choices the
/// form offers, while the model must tolerate any value the server sends.
const List<({String value, String label})> kBadgeVariants = [
  (value: 'secondary', label: 'رمادي'),
  (value: 'info', label: 'أزرق'),
  (value: 'success', label: 'أخضر'),
  (value: 'warning', label: 'برتقالي'),
  (value: 'danger', label: 'أحمر'),
];

/// The case-priority add/edit form section. State is owned by the page.
class CasePriorityFormFields extends StatelessWidget {
  const CasePriorityFormFields({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.nameArController,
    required this.descriptionController,
    required this.displayOrderController,
    required this.freePerMonthController,
    required this.surchargeController,
    required this.badgeVariant,
    required this.onBadgeVariantChanged,
    required this.isDefault,
    required this.onDefaultChanged,
    required this.isUnlimited,
    required this.onUnlimitedChanged,
    required this.isActive,
    required this.onActiveChanged,
    required this.isEditing,
    required this.isSubmitting,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController nameArController;
  final TextEditingController descriptionController;
  final TextEditingController displayOrderController;
  final TextEditingController freePerMonthController;
  final TextEditingController surchargeController;
  final String badgeVariant;
  final ValueChanged<String> onBadgeVariantChanged;
  final bool isDefault;
  final ValueChanged<bool> onDefaultChanged;
  final bool isUnlimited;
  final ValueChanged<bool> onUnlimitedChanged;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;
  final bool isEditing;
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
            hintText: 'أدخل اسم الأولوية بالإنجليزية',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(
              Icons.flag_outlined,
              color: context.glass.onGlassMuted,
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'الاسم مطلوب' : null,
          ),
          const SizedBox(height: 20),
          const _Label('الاسم بالعربية'),
          AppTextFormField(
            controller: nameArController,
            hintText: 'أدخل الاسم بالعربية',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(
              Icons.translate_outlined,
              color: context.glass.onGlassMuted,
            ),
            // Optional on the API, but it is the label the whole app shows,
            // so leaving it out means the priority reads in English.
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'الاسم بالعربية مطلوب'
                : null,
          ),
          const SizedBox(height: 20),
          const _Label('الوصف'),
          AppTextFormField(
            controller: descriptionController,
            hintText: 'أدخل وصف الأولوية (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(
              Icons.notes_outlined,
              color: context.glass.onGlassMuted,
            ),
            validator: (_) => null,
          ),
          const SizedBox(height: 20),
          const _Label('ترتيب العرض'),
          AppTextFormField(
            controller: displayOrderController,
            hintText: 'الأصغر يظهر أولاً',
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            prefixIcon: Icon(
              Icons.sort_outlined,
              color: context.glass.onGlassMuted,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              return int.tryParse(value.trim()) == null
                  ? 'الرجاء إدخال رقم صحيح'
                  : null;
            },
          ),
          const SizedBox(height: 20),
          const _Label('اللون'),
          _BadgeVariantPicker(
            selected: badgeVariant,
            onChanged: onBadgeVariantChanged,
          ),
          const SizedBox(height: 24),
          const _SectionTitle('الحصة الشهرية'),
          const SizedBox(height: 4),
          Text(
            'عدد الحالات المجانية لكل طبيب شهرياً بهذه الأولوية، والرسم الذي '
            'يُضاف بعد تجاوزها.',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: context.glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: 12),
          _SwitchTile(
            label: 'بدون حد شهري',
            value: isUnlimited,
            onChanged: onUnlimitedChanged,
          ),
          // The free-per-month count means nothing once the priority is
          // unlimited, so it comes and goes with the switch instead of
          // sitting there disabled.
          if (!isUnlimited) ...[
            const SizedBox(height: 12),
            const _Label('عدد الحالات المجانية شهرياً'),
            AppTextFormField(
              controller: freePerMonthController,
              hintText: 'مثال: 5',
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              prefixIcon: Icon(
                Icons.confirmation_number_outlined,
                color: context.glass.onGlassMuted,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final parsed = int.tryParse(value.trim());
                if (parsed == null) return 'الرجاء إدخال رقم صحيح';
                // Mirrors the API's own bounds, so an out-of-range value is
                // caught here rather than coming back as a 400.
                if (parsed < 0 || parsed > 1000) {
                  return 'القيمة يجب أن تكون بين 0 و 1000';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 12),
          const _Label('الرسم الإضافي'),
          AppTextFormField(
            controller: surchargeController,
            hintText: 'الرسم بعد تجاوز الحصة (اختياري)',
            textInputAction: TextInputAction.done,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icon(
              Icons.attach_money_outlined,
              color: context.glass.onGlassMuted,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final parsed = double.tryParse(value.trim());
              if (parsed == null) return 'الرجاء إدخال رقم صحيح';
              if (parsed < 0 || parsed > 1000000) {
                return 'القيمة يجب أن تكون بين 0 و 1000000';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _SwitchTile(
            label: 'الأولوية الافتراضية',
            value: isDefault,
            onChanged: onDefaultChanged,
          ),
          if (isEditing) ...[
            const SizedBox(height: 12),
            _SwitchTile(
              label: 'مفعّلة',
              value: isActive,
              onChanged: onActiveChanged,
            ),
          ],
          const SizedBox(height: 24),
          if (isSubmitting)
            const Center(child: CustomCircleProgressIndiacatorWidget())
          else
            CustomButtonWidget(
              onPressed: onSave,
              buttonText: isEditing ? 'حفظ التعديلات' : 'إضافة الأولوية',
            ),
        ],
      ),
    );
  }
}

/// Colour choices shown as swatch chips — the variant is a colour, so it is
/// picked as one rather than from a list of names.
class _BadgeVariantPicker extends StatelessWidget {
  const _BadgeVariantPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final variant in kBadgeVariants)
          ChoiceChip(
            label: Text(variant.label),
            selected: selected == variant.value,
            avatar: CircleAvatar(
              backgroundColor: badgeVariantColor(context, variant.value),
              radius: 8,
            ),
            onSelected: (_) => onChanged(variant.value),
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
        gradient: context.glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: context.glass.strokeColor),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.font14MediumText)),
          Switch(
            value: value,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
