import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_state.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The doctor add/edit form section — mirrors `CreateDoctorRequest` /
/// `UpdateDoctorRequest`: name, email, phone, address, gender, date of birth,
/// clinic and city (plus an active toggle when editing). All state is owned by
/// the parent page and passed in.
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
    required this.isSubmitting,
    required this.isEditing,
    required this.isActive,
    required this.onActiveChanged,
    required this.onSave,
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
  final bool isSubmitting;
  final bool isEditing;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Label('الاسم الأول'),
          AppTextFormField(
            controller: firstNameController,
            hintText: 'أدخل الاسم الأول',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.person_outline,
              color: AppColorsManger.textSecondary,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'الاسم الأول مطلوب'
                : null,
          ),
          const SizedBox(height: 20),
          const _Label('الاسم الأخير'),
          AppTextFormField(
            controller: lastNameController,
            hintText: 'أدخل الاسم الأخير',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.person_outline,
              color: AppColorsManger.textSecondary,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'الاسم الأخير مطلوب'
                : null,
          ),
          const SizedBox(height: 20),
          const _Label('البريد الإلكتروني'),
          AppTextFormField(
            controller: emailController,
            hintText: 'أدخل البريد الإلكتروني (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              return value.contains('@') ? null : 'بريد إلكتروني غير صالح';
            },
          ),
          const SizedBox(height: 20),
          const _Label('رقم الهاتف'),
          AppTextFormField(
            controller: phoneController,
            hintText: 'أدخل رقم الهاتف (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (_) => null,
          ),
          const SizedBox(height: 20),
          const _Label('العنوان'),
          AppTextFormField(
            controller: addressController,
            hintText: 'أدخل العنوان (اختياري)',
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (_) => null,
          ),
          const SizedBox(height: 20),
          const _Label('الجنس'),
          SegmentedButton<DoctorGender>(
            segments: const [
              ButtonSegment(value: DoctorGender.male, label: Text('ذكر')),
              ButtonSegment(value: DoctorGender.female, label: Text('أنثى')),
            ],
            selected: {gender},
            onSelectionChanged: (selection) => onGenderChanged(selection.first),
          ),
          const SizedBox(height: 20),
          const _Label('تاريخ الميلاد'),
          _PickerField(
            hintText: 'اختر تاريخ الميلاد (اختياري)',
            icon: Icons.cake_outlined,
            value: dateOfBirth,
            onTap: onPickDate,
          ),
          const SizedBox(height: 20),
          const _Label('العيادة'),
          _ClinicDropdown(value: clinicId, onChanged: onClinicChanged),
          const SizedBox(height: 20),
          const _Label('المدينة'),
          _CityDropdown(value: cityId, onChanged: onCityChanged),
          if (isEditing) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColorsManger.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColorsManger.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('نشط', style: AppTextStyles.font14MediumText),
                  ),
                  Switch(
                    value: isActive,
                    activeThumbColor: AppColorsManger.primary,
                    onChanged: onActiveChanged,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (isSubmitting)
            const Center(child: CustomCircleProgressIndiacatorWidget())
          else
            CustomButtonWidget(
              onPressed: onSave,
              buttonText: isEditing ? 'حفظ التعديلات' : 'إضافة الدكتور',
              textColor: Colors.white,
              backgroundColor: AppColorsManger.primary,
            ),
        ],
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
      child: Text(text, style: AppTextStyles.font14MediumText),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColorsManger.moreLightGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColorsManger.textSecondary),
            const SizedBox(width: 12),
            Text(
              value ?? hintText,
              style: value == null
                  ? AppTextStyles.font14RegularSecondary
                  : AppTextStyles.font14MediumText,
            ),
          ],
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
  });

  final String? value;
  final IconData icon;
  final String hintText;
  final List<DropdownMenuItem<String>>? items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: AppColorsManger.textSecondary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColorsManger.moreLightGray,
        prefixIcon: Icon(icon, color: AppColorsManger.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(hintText, style: AppTextStyles.font14RegularSecondary),
      items: items ?? const [],
      onChanged: items == null ? null : onChanged,
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
              : 'اختر العيادة (اختياري)',
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
