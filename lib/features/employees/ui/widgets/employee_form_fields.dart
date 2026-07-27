import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_state.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The employee add/edit form section — mirrors the employee create/update
/// fields plus, on create, the photo picker. State is owned by the parent page.
class EmployeeFormFields extends StatelessWidget {
  const EmployeeFormFields({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.nationalNumberController,
    required this.codeController,
    required this.phoneController,
    required this.addressController,
    required this.bankNameController,
    required this.bankAccountController,
    required this.gender,
    required this.onGenderChanged,
    required this.dateOfBirth,
    required this.onPickDate,
    required this.cityId,
    required this.onCityChanged,
    required this.isSubmitting,
    required this.isEditing,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController nationalNumberController;
  final TextEditingController codeController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController bankNameController;
  final TextEditingController bankAccountController;
  final EmployeeGender gender;
  final ValueChanged<EmployeeGender> onGenderChanged;
  final String? dateOfBirth;
  final VoidCallback onPickDate;
  final String? cityId;
  final ValueChanged<String?> onCityChanged;
  final bool isSubmitting;
  final bool isEditing;
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
          const _Label('الرقم الوطني'),
          AppTextFormField(
            controller: nationalNumberController,
            hintText: 'أدخل الرقم الوطني (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.badge_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (_) => null,
          ),
          const SizedBox(height: 20),
          const _Label('رمز الموظف'),
          AppTextFormField(
            controller: codeController,
            hintText: 'أدخل رمز الموظف (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.numbers_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (_) => null,
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
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (_) => null,
          ),
          const SizedBox(height: 20),
          const _Label('اسم البنك'),
          AppTextFormField(
            controller: bankNameController,
            hintText: 'أدخل اسم البنك (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.account_balance_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (_) => null,
          ),
          const SizedBox(height: 20),
          const _Label('رقم الحساب البنكي'),
          AppTextFormField(
            controller: bankAccountController,
            hintText: 'أدخل رقم الحساب البنكي (اختياري)',
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(
              Icons.credit_card_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (_) => null,
          ),
          const SizedBox(height: 20),
          const _Label('الجنس'),
          SegmentedButton<EmployeeGender>(
            segments: const [
              ButtonSegment(value: EmployeeGender.male, label: Text('ذكر')),
              ButtonSegment(value: EmployeeGender.female, label: Text('أنثى')),
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
          const _Label('المدينة'),
          _CityDropdown(value: cityId, onChanged: onCityChanged),
          const SizedBox(height: 24),
          if (isSubmitting)
            const Center(child: CustomCircleProgressIndiacatorWidget())
          else
            CustomButtonWidget(
              onPressed: onSave,
              buttonText: isEditing ? 'حفظ التعديلات' : 'إضافة الموظف',
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
            prefixIcon: const Icon(
              Icons.location_city_outlined,
              color: AppColorsManger.textSecondary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          hint: Text(
            state is CitiesLoading
                ? 'جارٍ تحميل المدن...'
                : 'اختر المدينة (اختياري)',
            style: AppTextStyles.font14RegularSecondary,
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
