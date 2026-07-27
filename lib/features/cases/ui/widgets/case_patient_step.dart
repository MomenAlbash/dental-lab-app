import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cases/data/models/case_priority.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 1 — patient, doctor/clinic, priority, due date and notes.
class CasePatientStep extends StatelessWidget {
  const CasePatientStep({
    super.key,
    required this.patientNameController,
    required this.referenceController,
    required this.notesController,
    required this.doctorId,
    required this.onDoctorChanged,
    required this.clinicId,
    required this.onClinicChanged,
    required this.priority,
    required this.onPriorityChanged,
    required this.dueDate,
    required this.onPickDueDate,
  });

  final TextEditingController patientNameController;
  final TextEditingController referenceController;
  final TextEditingController notesController;
  final String? doctorId;
  final ValueChanged<String?> onDoctorChanged;
  final String? clinicId;
  final ValueChanged<String?> onClinicChanged;
  final CasePriority priority;
  final ValueChanged<CasePriority> onPriorityChanged;
  final DateTime? dueDate;
  final VoidCallback onPickDueDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('اسم المريض'),
        AppTextFormField(
          controller: patientNameController,
          hintText: 'أدخل اسم المريض',
          prefixIcon: const Icon(
            Icons.personal_injury_outlined,
            color: AppColorsManger.textSecondary,
          ),
          validator: (_) => null,
        ),
        const SizedBox(height: 16),
        const _Label('الطبيب'),
        BlocBuilder<DoctorsCubit, DoctorsState>(
          builder: (context, state) {
            final doctors = state is DoctorsLoaded ? state.doctors : null;
            return CaseLookupDropdown(
              value: doctorId,
              icon: Icons.medical_services_outlined,
              hintText: state is DoctorsLoading
                  ? 'جارٍ تحميل الأطباء...'
                  : 'اختر الطبيب',
              items: doctors
                  ?.map(
                    (d) => DropdownMenuItem(
                      value: d.id,
                      child: Text(d.fullName),
                    ),
                  )
                  .toList(),
              onChanged: onDoctorChanged,
            );
          },
        ),
        const SizedBox(height: 16),
        const _Label('العيادة'),
        BlocBuilder<ClinicsCubit, ClinicsState>(
          builder: (context, state) {
            final clinics = state is ClinicsLoaded ? state.clinics : null;
            return CaseLookupDropdown(
              value: clinicId,
              icon: Icons.local_hospital_outlined,
              hintText: state is ClinicsLoading
                  ? 'جارٍ تحميل العيادات...'
                  : 'اختر العيادة (اختياري)',
              items: clinics
                  ?.map(
                    (c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: onClinicChanged,
            );
          },
        ),
        const SizedBox(height: 16),
        const _Label('الأولوية'),
        SegmentedButton<CasePriority>(
          segments: CasePriority.values
              .map(
                (p) => ButtonSegment(value: p, label: Text(p.arabicLabel)),
              )
              .toList(),
          selected: {priority},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onPriorityChanged(s.first),
        ),
        const SizedBox(height: 16),
        const _Label('تاريخ التسليم'),
        InkWell(
          onTap: onPickDueDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: AppColorsManger.moreLightGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  color: AppColorsManger.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  dueDate == null
                      ? 'اختر تاريخ التسليم (اختياري)'
                      : '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
                  style: dueDate == null
                      ? AppTextStyles.font14RegularSecondary
                      : AppTextStyles.font14MediumText,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _Label('الرقم المرجعي'),
        AppTextFormField(
          controller: referenceController,
          hintText: 'أدخل الرقم المرجعي (اختياري)',
          prefixIcon: const Icon(
            Icons.tag_outlined,
            color: AppColorsManger.textSecondary,
          ),
          validator: (_) => null,
        ),
        const SizedBox(height: 16),
        const _Label('ملاحظات'),
        AppTextFormField(
          controller: notesController,
          hintText: 'ملاحظات (اختياري)',
          prefixIcon: const Icon(
            Icons.notes_outlined,
            color: AppColorsManger.textSecondary,
          ),
          validator: (_) => null,
        ),
      ],
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
