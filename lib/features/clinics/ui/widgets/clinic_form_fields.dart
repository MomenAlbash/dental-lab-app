import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The clinic add/edit form section: the labelled inputs, the city picker and
/// the submit button. State (controllers, selected city, submission) is owned
/// by the parent page and passed in.
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
    required this.isSubmitting,
    required this.isEditing,
    required this.onSave,
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
          const _Label('اسم العيادة'),
          AppTextFormField(
            controller: nameController,
            hintText: 'أدخل اسم العيادة',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.local_hospital_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'اسم العيادة مطلوب'
                : null,
          ),
          const SizedBox(height: 20),
          const _Label('الرمز'),
          AppTextFormField(
            controller: codeController,
            hintText: 'أدخل رمز العيادة (اختياري)',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.tag_outlined,
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
          const _Label('الموقع الإلكتروني'),
          AppTextFormField(
            controller: websiteController,
            hintText: 'أدخل رابط الموقع (اختياري)',
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(
              Icons.language_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (_) => null,
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
              buttonText: isEditing ? 'حفظ التعديلات' : 'إضافة العيادة',
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

/// Full-width city picker fed by the standalone [CitiesCubit]. The city is
/// optional, so a failed lookup falls back to an empty (disabled) dropdown
/// rather than blocking the form.
class _CityDropdown extends StatelessWidget {
  const _CityDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CitiesCubit, CitiesState>(
      builder: (context, state) {
        final cities = state is CitiesLoaded ? state.cities : null;
        final isLoading = state is CitiesLoading;

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
            isLoading ? 'جارٍ تحميل المدن...' : 'اختر المدينة (اختياري)',
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
