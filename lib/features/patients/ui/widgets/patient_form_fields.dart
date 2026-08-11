import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_gender.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The patient add form — mirrors `CreatePatientRequest`. All state is owned
/// by the parent page and passed in.
///
/// Laid out like the doctor form (live preview, numbered sections, sticky
/// save bar) so the two screens read as one product, adapted for what a
/// patient actually needs: the doctor/clinic link comes first because every
/// other field depends on it, and notes replace the doctor form's address.
class PatientFormFields extends StatelessWidget {
  const PatientFormFields({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.notesController,
    required this.gender,
    required this.onGenderChanged,
    required this.dateOfBirth,
    required this.onPickDate,
    required this.doctorId,
    required this.onDoctorChanged,
    required this.clinicName,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController notesController;
  final PatientGender gender;
  final ValueChanged<PatientGender> onGenderChanged;
  final String? dateOfBirth;
  final VoidCallback onPickDate;
  final String? doctorId;
  final ValueChanged<String?> onDoctorChanged;

  /// Derived by the page from the selected doctor, since a patient's clinic
  /// always follows their doctor rather than being picked independently.
  final String? clinicName;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PatientFormPreview(
            firstName: firstNameController.text,
            lastName: lastNameController.text,
            doctorId: doctorId,
            gender: gender,
          ),
          const SizedBox(height: AppSpacing.xl),

          _FormSection(
            step: 1,
            title: 'الطبيب المعالج',
            subtitle: 'العيادة تُشتق تلقائياً من الطبيب',
            children: [
              _DoctorPicker(value: doctorId, onChanged: onDoctorChanged),
              _ReadOnlyField(
                icon: Icons.local_hospital_outlined,
                text:
                    clinicName ??
                    (doctorId == null
                        ? 'اختر الطبيب أولاً'
                        : 'الطبيب غير مرتبط بعيادة'),
                isPlaceholder: clinicName == null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _FormSection(
            step: 2,
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
                hintText: 'أدخل الاسم الأخير (اختياري)',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (_) => null,
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
            step: 3,
            title: 'التواصل والملاحظات',
            subtitle: 'اختياري',
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
                controller: notesController,
                textField: 'ملاحظات',
                hintText: 'ملاحظات (اختياري)',
                textInputAction: TextInputAction.done,
                maxLines: 3,
                prefixIcon: const Icon(Icons.notes_outlined),
                validator: (_) => null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Live summary card, matching the doctor form's preview.
class PatientFormPreview extends StatelessWidget {
  const PatientFormPreview({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.doctorId,
    required this.gender,
  });

  final String firstName;
  final String lastName;
  final String? doctorId;
  final PatientGender gender;

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
                      'مريض جديد',
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
                          icon: gender == PatientGender.male
                              ? Icons.male_outlined
                              : Icons.female_outlined,
                          label: gender.arabicLabel,
                        ),
                        const SizedBox(width: 6),
                        _DoctorChip(doctorId: doctorId),
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

class _DoctorChip extends StatelessWidget {
  const _DoctorChip({required this.doctorId});

  final String? doctorId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoctorsCubit, DoctorsState>(
      builder: (context, state) {
        String label = 'اختر الطبيب';
        if (doctorId != null && state is DoctorsLoaded) {
          for (final doctor in state.doctors) {
            if (doctor.id == doctorId) {
              label = 'د. ${doctor.fullName}';
              break;
            }
          }
        }
        return Flexible(
          child: _PreviewChip(
            icon: Icons.medical_services_outlined,
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

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.value, required this.onChanged});

  final PatientGender value;
  final ValueChanged<PatientGender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in PatientGender.values) ...[
          if (option != PatientGender.values.first)
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

  final PatientGender gender;
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
                gender == PatientGender.male
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

/// Non-interactive field — used for the clinic once it's derived from the
/// selected doctor, since there's nothing left for the user to pick.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.icon,
    required this.text,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String text;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: glass.onGlassMuted.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: glass.onGlassMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: isPlaceholder
                  ? AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    )
                  : AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorPicker extends StatelessWidget {
  const _DoctorPicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoctorsCubit, DoctorsState>(
      builder: (context, state) {
        final doctors = state is DoctorsLoaded ? state.doctors : null;

        if (doctors != null && doctors.isEmpty) {
          return _NoDoctorsNotice(
            onAddDoctor: () async {
              final added = await context.push<bool>(Routes.doctorFormScreen);
              if (added == true && context.mounted) {
                context.read<DoctorsCubit>().getDoctors();
              }
            },
          );
        }

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
            prefixIcon: Icon(
              Icons.medical_services_outlined,
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
            state is DoctorsLoading ? 'جارٍ تحميل الأطباء...' : 'اختر الطبيب',
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          items:
              doctors
                  ?.map(
                    (d) =>
                        DropdownMenuItem(value: d.id, child: Text(d.fullName)),
                  )
                  .toList() ??
              const [],
          onChanged: doctors == null ? null : onChanged,
        );
      },
    );
  }
}

/// Shown instead of the doctor dropdown when the lab has no doctors yet —
/// picking one is required, so this is a dead end without a way out.
class _NoDoctorsNotice extends StatelessWidget {
  const _NoDoctorsNotice({required this.onAddDoctor});

  final VoidCallback onAddDoctor;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.glass.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: context.glass.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: context.glass.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'ما في أطباء مسجّلين بعد — لازم تضيف طبيب أولاً',
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onAddDoctor,
            icon: const Icon(Icons.add),
            label: const Text('إضافة طبيب'),
          ),
        ],
      ),
    );
  }
}
