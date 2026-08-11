import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_state.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The doctor add/edit form — mirrors `CreateDoctorRequest` /
/// `UpdateDoctorRequest`. All state is owned by the parent page and passed in.
///
/// Laid out as a live preview card followed by numbered sections rather than
/// one long label/field column: the user sees the record taking shape as they
/// type, and the grouping turns a 9-field wall into three short tasks.
class DoctorFormFields extends StatelessWidget {
  const DoctorFormFields({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.gender,
    required this.onGenderChanged,
    required this.dateOfBirth,
    required this.onPickDate,
    required this.cityId,
    required this.onCityChanged,
    required this.clinicId,
    required this.onClinicChanged,
    required this.isEditing,
    required this.isActive,
    required this.onActiveChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final DoctorGender gender;
  final ValueChanged<DoctorGender> onGenderChanged;
  final String? dateOfBirth;
  final VoidCallback onPickDate;
  final String? cityId;
  final ValueChanged<String?> onCityChanged;
  final String? clinicId;
  final ValueChanged<String?> onClinicChanged;
  final bool isEditing;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DoctorFormPreview(
            firstName: firstNameController.text,
            lastName: lastNameController.text,
            clinicId: clinicId,
            gender: gender,
            isActive: isActive,
            isEditing: isEditing,
          ),
          const SizedBox(height: AppSpacing.xl),

          _FormSection(
            step: 1,
            title: 'الهوية',
            subtitle: 'الاسم والجنس وتاريخ الميلاد',
            children: [
              AppTextFormField(
                controller: firstNameController,
                textField: 'الاسم الأول',
                hintText: 'أدخل الاسم الأول',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'الاسم الأول مطلوب'
                    : null,
              ),
              AppTextFormField(
                controller: lastNameController,
                textField: 'الاسم الأخير',
                hintText: 'أدخل الاسم الأخير',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'الاسم الأخير مطلوب'
                    : null,
              ),
              _FieldLabel('الجنس'),
              _GenderSelector(value: gender, onChanged: onGenderChanged),
              _FieldLabel('تاريخ الميلاد'),
              _PickerField(
                hintText: 'اختر تاريخ الميلاد (اختياري)',
                icon: Icons.cake_outlined,
                value: dateOfBirth,
                onTap: onPickDate,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _FormSection(
            step: 2,
            title: 'التواصل',
            subtitle: 'كيف نصل إلى الدكتور',
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
                controller: addressController,
                textField: 'العنوان',
                hintText: 'أدخل العنوان (اختياري)',
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: (_) => null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _FormSection(
            step: 3,
            title: 'الارتباطات',
            subtitle: 'العيادة والمدينة',
            children: [
              _FieldLabel('العيادة'),
              _ClinicDropdown(value: clinicId, onChanged: onClinicChanged),
              _FieldLabel('المدينة'),
              _CityDropdown(value: cityId, onChanged: onCityChanged),
              if (isEditing) ...[
                const SizedBox(height: AppSpacing.xs),
                _ActiveToggle(value: isActive, onChanged: onActiveChanged),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Live summary of what is being entered. Updates as the name is typed, which
/// turns an otherwise blind form into something with immediate feedback.
class DoctorFormPreview extends StatelessWidget {
  const DoctorFormPreview({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.clinicId,
    required this.gender,
    required this.isActive,
    required this.isEditing,
  });

  final String firstName;
  final String lastName;
  final String? clinicId;
  final DoctorGender gender;
  final bool isActive;
  final bool isEditing;

  String get _fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  String get _initials {
    final parts = [
      firstName.trim(),
      lastName.trim(),
    ].where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.map((part) => part.characters.first).take(2).join();
  }

  @override
  Widget build(BuildContext context) {
    final hasName = _fullName.isNotEmpty;
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
                // Keyed so the initials cross-fade as the name is typed.
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
                      isEditing ? 'تعديل بيانات' : 'دكتور جديد',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasName ? _fullName : 'اكتب الاسم ليظهر هنا',
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
                        _PreviewChip(
                          icon: gender == DoctorGender.male
                              ? Icons.male_outlined
                              : Icons.female_outlined,
                          label: gender.arabicLabel,
                        ),
                        const SizedBox(width: 6),
                        if (isEditing)
                          _PreviewChip(
                            icon: isActive
                                ? Icons.check_circle_outline
                                : Icons.pause_circle_outline,
                            label: isActive ? 'نشط' : 'موقوف',
                          )
                        else
                          _ClinicChip(clinicId: clinicId),
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

/// Resolves the selected clinic's name for the preview chip.
class _ClinicChip extends StatelessWidget {
  const _ClinicChip({required this.clinicId});

  final String? clinicId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClinicsCubit, ClinicsState>(
      builder: (context, state) {
        String label = 'بدون عيادة';
        if (clinicId != null && state is ClinicsLoaded) {
          for (final clinic in state.clinics) {
            if (clinic.id == clinicId) {
              label = clinic.name;
              break;
            }
          }
        }
        return Flexible(
          child: _PreviewChip(
            icon: Icons.local_hospital_outlined,
            label: label,
          ),
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

/// A numbered group of related fields.
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

/// Two tappable cards instead of a SegmentedButton — a larger target and a
/// clearer selected state at a glance.
class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.value, required this.onChanged});

  final DoctorGender value;
  final ValueChanged<DoctorGender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in DoctorGender.values) ...[
          if (option != DoctorGender.values.first)
            const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _GenderOption(
              gender: option,
              selected: value == option,
              onTap: () => onChanged(option),
            ),
          ),
        ],
      ],
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.gender,
    required this.selected,
    required this.onTap,
  });

  final DoctorGender gender;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;
    final radius = BorderRadius.circular(AppRadius.glass);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: selected ? accent.withValues(alpha: 0.14) : glass.fillColor,
            border: Border.all(
              color: selected ? accent : glass.strokeColor,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                gender == DoctorGender.male
                    ? Icons.male_outlined
                    : Icons.female_outlined,
                size: 19,
                color: selected ? accent : glass.onGlassMuted,
              ),
              const SizedBox(width: 6),
              Text(
                gender.arabicLabel,
                style: AppTextStyles.font14MediumText.copyWith(
                  color: selected ? accent : glass.onGlass,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveToggle extends StatelessWidget {
  const _ActiveToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = value ? context.glass.success : glass.onGlassMuted;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: glass.fillColor,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Row(
        children: [
          Icon(Icons.toggle_on_outlined, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الحالة',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                Text(
                  value ? 'نشط' : 'موقوف',
                  style: AppTextStyles.font12RegularHint.copyWith(color: color),
                ),
              ],
            ),
          ),
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

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.hintText,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String hintText;
  final IconData icon;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: glass.fillColor,
            borderRadius: radius,
            border: Border.all(color: glass.strokeColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: glass.onGlassMuted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  value ?? hintText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: value == null
                      ? AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlassMuted,
                        )
                      : AppTextStyles.font14MediumText.copyWith(
                          color: glass.onGlass,
                        ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 17,
                color: glass.onGlassMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width, boxed dropdown shared by the city and clinic pickers.
class _LookupDropdown extends StatelessWidget {
  const _LookupDropdown({
    required this.value,
    required this.icon,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String? value;
  final IconData icon;
  final String hintText;
  final List<DropdownMenuItem<String>>? items;
  final ValueChanged<String?> onChanged;

  /// Null for optional pickers — the surrounding [Form] then has nothing to
  /// check for this field.
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
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
        prefixIcon: Icon(icon, color: glass.onGlassMuted),
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
        hintText,
        style: AppTextStyles.font14RegularSecondary.copyWith(
          color: glass.onGlassMuted,
        ),
      ),
      items: items ?? const [],
      onChanged: items == null ? null : onChanged,
      validator: validator,
    );
  }
}

/// City picker fed by the standalone [CitiesCubit].
class _CityDropdown extends StatelessWidget {
  const _CityDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CitiesCubit, CitiesState>(
      builder: (context, state) {
        final cities = state is CitiesLoaded ? state.cities : null;
        return _LookupDropdown(
          value: value,
          icon: Icons.location_city_outlined,
          hintText: state is CitiesLoading
              ? 'جارٍ تحميل المدن...'
              : 'اختر المدينة (اختياري)',
          items: cities
              ?.map(
                (city) => DropdownMenuItem(
                  value: city.id,
                  child: Text(city.name ?? '—'),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}

/// Clinic picker fed by the [ClinicsCubit] from the clinics feature.
class _ClinicDropdown extends StatelessWidget {
  const _ClinicDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClinicsCubit, ClinicsState>(
      builder: (context, state) {
        final clinics = state is ClinicsLoaded ? state.clinics : null;
        return _LookupDropdown(
          value: value,
          icon: Icons.local_hospital_outlined,
          hintText: state is ClinicsLoading
              ? 'جارٍ تحميل العيادات...'
              : 'اختر العيادة',
          // Required: a doctor without a clinic cannot be reached through the
          // clinic listings the rest of the app is organised around.
          validator: (value) =>
              (value == null || value.isEmpty) ? 'اختر العيادة' : null,
          items: clinics
              ?.map(
                (clinic) => DropdownMenuItem(
                  value: clinic.id,
                  child: Text(clinic.name),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
