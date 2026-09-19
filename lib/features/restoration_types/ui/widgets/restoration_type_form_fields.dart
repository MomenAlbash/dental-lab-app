import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/save_restoration_type_price_request_model.dart';
import 'package:flutter/material.dart';

/// The restoration-type add/edit form section. State is owned by the page.
class RestorationTypeFormFields extends StatelessWidget {
  const RestorationTypeFormFields({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.nameArController,
    required this.descriptionController,
    required this.transparencyController,
    required this.durationControllers,
    required this.pricingType,
    required this.onPricingTypeChanged,
    required this.currencies,
    required this.loadingCurrencies,
    required this.prices,
    required this.onAddPrice,
    required this.onRemovePrice,
    required this.isEditing,
    required this.isActive,
    required this.onActiveChanged,
    required this.isSubmitting,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController nameArController;
  final TextEditingController descriptionController;
  final TextEditingController transparencyController;

  /// Every currency the lab has, for the "add a price" dialog to offer.
  final List<CurrencyModel> currencies;
  final bool loadingCurrencies;

  /// One row per currency this type is priced in, alongside
  /// [defaultPriceController]'s currency-less list price. Empty is the
  /// ordinary case for a single-currency laboratory.
  final List<SaveRestorationTypePriceRequestModel> prices;
  final VoidCallback onAddPrice;
  final ValueChanged<int> onRemovePrice;

  /// One controller per priority level, keyed by the level so each row can
  /// label itself with the name the lab wrote.
  final Map<CasePriorityModel, TextEditingController> durationControllers;
  final int pricingType;
  final ValueChanged<int> onPricingTypeChanged;
  final bool isEditing;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;

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
            prefixIcon: Icon(
              Icons.category_outlined,
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
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'الاسم بالعربية مطلوب'
                : null,
          ),
          const SizedBox(height: 20),
          const _Label('الوصف'),
          AppTextFormField(
            controller: descriptionController,
            hintText: 'أدخل وصف التعويض (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(
              Icons.notes_outlined,
              color: context.glass.onGlassMuted,
            ),
            validator: (_) => null,
          ),
          const SizedBox(height: 24),
          _SectionTitle('الأسعار حسب العملة'),
          const SizedBox(height: 4),
          Text(
            'يجب إضافة سعر واحد على الأقل — لا يوجد سعر افتراضي بدون عملة. '
            'إذا المخبر بيسعّر هالتعويض بأكثر من عملة (مثلاً ليرة سورية '
            'ودولار)، أضف سعراً لكل عملة هون. عند إضافة تعويض على حالة، هيدا '
            'هو السعر يلي رح ينعبى تلقائياً حسب العملة المختارة.',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: context.glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: 12),
          if (prices.isEmpty)
            Text(
              'لا يوجد سعر بعد — أضف واحداً قبل الحفظ',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: context.glass.warning,
              ),
            )
          else
            for (var i = 0; i < prices.length; i++) ...[
              _CurrencyPriceRow(
                price: prices[i],
                currencyLabel: _currencyLabel(prices[i].currencyId),
                onRemove: () => onRemovePrice(i),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: loadingCurrencies ? null : onAddPrice,
            icon: const Icon(Icons.add),
            label: Text(
              loadingCurrencies ? 'جارٍ تحميل العملات...' : 'إضافة سعر لعملة',
            ),
          ),
          const SizedBox(height: 20),
          const _Label('نسبة الشفافية'),
          AppTextFormField(
            controller: transparencyController,
            hintText: 'أدخل نسبة الشفافية (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(
              Icons.opacity_outlined,
              color: context.glass.onGlassMuted,
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
          const SizedBox(height: 4),
          Text(
            'صف لكل أولوية أعلنها المخبر. اترك الحقل فارغاً إن لم تُقدَّر '
            'المدة بعد.',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: context.glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: 12),
          // One row per priority the lab declared — not four fixed boxes. The
          // old Low/Normal/High/Urgent came from an enum the API retired: a lab
          // with two tiers was shown four, and one with six could fill only
          // four of them.
          if (durationControllers.isEmpty)
            Text(
              'لا توجد أولويات معرّفة بعد — عرّفها من شاشة الأولويات',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: context.glass.onGlassMuted,
              ),
            )
          else
            for (final entry in durationControllers.entries) ...[
              _DurationField(
                label: entry.key.displayName,
                controller: entry.value,
              ),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 24),
          // No stage editor here any more. The create/update endpoints declare
          // no `stages` field, so everything typed in it was dropped on the
          // floor — a type saved with five stages opened with none, which is
          // exactly what the route screen was reporting.
          _SectionTitle('مراحل التصنيع'),
          const SizedBox(height: 4),
          Text(
            'تُضاف من شاشة "مسار التعويض" بعد حفظ النوع — لكل مرحلة ترتيب '
            'وطريقة استلام وإسناد، وهي أكبر من أن تُختصر هنا.',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: context.glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: 24),
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
            ),
        ],
      ),
    );
  }

  String _currencyLabel(String currencyId) {
    for (final currency in currencies) {
      if (currency.id == currencyId) {
        return currency.name ?? currency.code ?? currency.symbol ?? '—';
      }
    }
    return '—';
  }
}

class _CurrencyPriceRow extends StatelessWidget {
  const _CurrencyPriceRow({
    required this.price,
    required this.currencyLabel,
    required this.onRemove,
  });

  final SaveRestorationTypePriceRequestModel price;
  final String currencyLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.currency_exchange_outlined,
            size: 18,
            color: glass.onGlassMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(currencyLabel, style: AppTextStyles.font14MediumText),
          ),
          Text(
            price.price.toStringAsFixed(0),
            style: AppTextStyles.font14MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          IconButton(
            tooltip: 'حذف',
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 18, color: glass.error),
          ),
        ],
      ),
    );
  }
}

/// The ordered list of workflow stages, with add/remove and a "final stage"
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
            prefixIcon: Icon(
              Icons.timer_outlined,
              color: context.glass.onGlassMuted,
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
        gradient: context.glass.surfaceGradient,
        borderRadius: BorderRadius.circular(14),
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
