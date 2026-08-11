import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The clinic add/edit form — mirrors `CreateClinicRequest` /
/// `UpdateClinicRequest`. All state is owned by the parent page and passed
/// in.
///
/// Laid out like the doctor/patient forms (live preview, numbered sections,
/// sticky save bar) so all three read as one product.
class ClinicFormFields extends StatelessWidget {
  const ClinicFormFields({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.codeController,
    required this.addressController,
    required this.phoneController,
    required this.emailController,
    required this.websiteController,
    required this.cityId,
    required this.onCityChanged,
    required this.isEditing,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController websiteController;
  final String? cityId;
  final ValueChanged<String?> onCityChanged;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClinicFormPreview(
            name: nameController.text,
            code: codeController.text,
            cityId: cityId,
            isEditing: isEditing,
          ),
          const SizedBox(height: AppSpacing.xl),

          _FormSection(
            step: 1,
            title: 'الهوية',
            subtitle: 'اسم العيادة ورمزها',
            children: [
              AppTextFormField(
                controller: nameController,
                textField: 'اسم العيادة',
                hintText: 'أدخل اسم العيادة',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.local_hospital_outlined),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'اسم العيادة مطلوب'
                    : null,
              ),
              AppTextFormField(
                controller: codeController,
                textField: 'الرمز',
                hintText: 'أدخل رمز العيادة (اختياري)',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.tag_outlined),
                validator: (_) => null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _FormSection(
            step: 2,
            title: 'التواصل',
            subtitle: 'كيف نصل إلى العيادة',
            children: [
              AppTextFormField(
                controller: phoneController,
                textField: 'رقم الهاتف',
                hintText: 'أدخل رقم الهاتف (اختياري)',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.phone_outlined),
                validator: (_) => null,
              ),
              AppTextFormField(
                controller: emailController,
                textField: 'البريد الإلكتروني',
                hintText: 'أدخل البريد الإلكتروني (اختياري)',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  return value.contains('@') ? null : 'بريد إلكتروني غير صالح';
                },
              ),
              AppTextFormField(
                controller: websiteController,
                textField: 'الموقع الإلكتروني',
                hintText: 'أدخل رابط الموقع (اختياري)',
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.language_outlined),
                validator: (_) => null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _FormSection(
            step: 3,
            title: 'الموقع',
            subtitle: 'العنوان والمدينة',
            children: [
              AppTextFormField(
                controller: addressController,
                textField: 'العنوان',
                hintText: 'أدخل العنوان (اختياري)',
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.map_outlined),
                validator: (_) => null,
              ),
              _FieldLabel('المدينة'),
              _CityDropdown(value: cityId, onChanged: onCityChanged),
            ],
          ),
        ],
      ),
    );
  }
}

/// Live summary of the clinic being entered — matches the doctor/patient
/// forms' preview card.
class ClinicFormPreview extends StatelessWidget {
  const ClinicFormPreview({
    super.key,
    required this.name,
    required this.code,
    required this.cityId,
    required this.isEditing,
  });

  final String name;
  final String code;
  final String? cityId;
  final bool isEditing;

  String get _initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    return words.map((word) => word.characters.first).take(2).join();
  }

  @override
  Widget build(BuildContext context) {
    final hasName = name.trim().isNotEmpty;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.glassLg),
            gradient: context.glass.brandGradient,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.32),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppMotion.base,
                curve: AppMotion.enter,
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: hasName ? 0.26 : 0.14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Text(
                    _initials,
                    key: ValueKey(_initials),
                    style: AppTextStyles.font20BoldText.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEditing ? 'تعديل عيادة' : 'عيادة جديدة',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasName ? name.trim() : 'اكتب اسم العيادة ليظهر هنا',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.font18MediumText.copyWith(
                        color: hasName
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        // Flexible on both: unlike the doctor form's fixed-label
                        // gender chip, a clinic code is free text and can be long
                        // enough at large text scales to overflow the row on its
                        // own if it isn't allowed to shrink too.
                        if (code.trim().isNotEmpty) ...[
                          Flexible(
                            child: _PreviewChip(
                              icon: Icons.tag_outlined,
                              label: code.trim(),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        _CityChip(cityId: cityId),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .slideY(begin: -0.1, duration: AppMotion.base, curve: AppMotion.enter);
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({required this.cityId});

  final String? cityId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CitiesCubit, CitiesState>(
      builder: (context, state) {
        String label = 'بدون مدينة';
        if (cityId != null && state is CitiesLoaded) {
          for (final city in state.cities) {
            if (city.id == cityId) {
              label = city.name ?? label;
              break;
            }
          }
        }
        return Flexible(
          child: _PreviewChip(icon: Icons.location_city_outlined, label: label),
        );
      },
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final int step;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            borderRadius: BorderRadius.circular(AppRadius.glassLg),
            border: Border.all(color: glass.strokeColor),
            boxShadow: glass.shadows,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.16),
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '$step',
                      style: AppTextStyles.font13MediumPrimary.copyWith(
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.font16MediumText.copyWith(
                            color: glass.onGlass,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AppTextStyles.font12RegularHint.copyWith(
                            color: glass.onGlassMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                children[i],
              ],
            ],
          ),
        )
        .animate(delay: AppMotion.stagger * step)
        .fadeIn(duration: AppMotion.base)
        .slideY(begin: 0.06, duration: AppMotion.base, curve: AppMotion.enter);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: AppTextStyles.font13MediumPrimary.copyWith(
          color: context.glass.onGlassMuted,
        ),
      ),
    );
  }
}

/// City picker fed by the standalone [CitiesCubit]. The city is optional, so
/// a failed lookup falls back to an empty (disabled) dropdown rather than
/// blocking the form.
class _CityDropdown extends StatelessWidget {
  const _CityDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CitiesCubit, CitiesState>(
      builder: (context, state) {
        final glass = context.glass;
        final cities = state is CitiesLoaded ? state.cities : null;
        final border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.glass),
          borderSide: BorderSide(color: glass.strokeColor),
        );

        return DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: AppTextStyles.font14MediumText.copyWith(color: glass.onGlass),
          dropdownColor: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.glass),
          icon: Icon(Icons.keyboard_arrow_down, color: glass.onGlassMuted),
          decoration: InputDecoration(
            filled: true,
            fillColor: glass.fillColor,
            prefixIcon: Icon(
              Icons.location_city_outlined,
              color: glass.onGlassMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: AppSpacing.xs,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.6,
              ),
            ),
          ),
          hint: Text(
            state is CitiesLoading
                ? 'جارٍ تحميل المدن...'
                : 'اختر المدينة (اختياري)',
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          items: (cities ?? [])
              .map(
                (city) => DropdownMenuItem(
                  value: city.id,
                  child: Text(city.name ?? '—'),
                ),
              )
              .toList(),
          onChanged: cities == null ? null : onChanged,
        );
      },
    );
  }
}
