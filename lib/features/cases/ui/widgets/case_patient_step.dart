import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cases/data/models/case_priority.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Step 1 — patient, doctor/clinic, priority, due date and notes.
class CasePatientStep extends StatelessWidget {
  const CasePatientStep({
    super.key,
    required this.patientId,
    required this.onPatientChanged,
    required this.referenceController,
    required this.notesController,
    required this.doctorId,
    required this.onDoctorChanged,
    required this.priority,
    required this.onPriorityChanged,
    required this.dueDate,
    required this.onPickDueDate,
    required this.receivedAt,
    required this.onPickReceivedAt,
  });

  final String? patientId;
  final void Function(String? id, PatientModel? patient) onPatientChanged;
  final TextEditingController referenceController;
  final TextEditingController notesController;
  final String? doctorId;
  final void Function(String? doctorId, String? clinicId) onDoctorChanged;
  final CasePriority priority;
  final ValueChanged<CasePriority> onPriorityChanged;
  final DateTime? dueDate;
  final VoidCallback onPickDueDate;
  final DateTime? receivedAt;
  final VoidCallback onPickReceivedAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('الطبيب'),
        BlocBuilder<DoctorsCubit, DoctorsState>(
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
              onChanged: (id) {
                String? clinicId;
                if (id != null && doctors != null) {
                  for (final d in doctors) {
                    if (d.id == id) {
                      clinicId = d.clinicId;
                      break;
                    }
                  }
                }
                onDoctorChanged(id, clinicId);
              },
            );
          },
        ),
        const SizedBox(height: 16),
        const _Label('العيادة'),
        BlocBuilder<DoctorsCubit, DoctorsState>(
          builder: (context, state) {
            final doctors = state is DoctorsLoaded ? state.doctors : null;
            DoctorModel? selectedDoctor;
            if (doctors != null && doctorId != null) {
              for (final d in doctors) {
                if (d.id == doctorId) {
                  selectedDoctor = d;
                  break;
                }
              }
            }

            // A doctor belongs to at most one clinic, so once a doctor is
            // picked there's nothing left to choose — show it read-only
            // instead of a dropdown with a single (or no) option.
            final String hintText;
            if (doctorId == null) {
              hintText = 'اختر الطبيب أولاً';
            } else if (selectedDoctor?.clinicName == null) {
              hintText = 'الطبيب غير مرتبط بعيادة';
            } else {
              hintText = '';
            }

            return _ReadOnlyField(
              icon: Icons.local_hospital_outlined,
              text: selectedDoctor?.clinicName ?? hintText,
              isPlaceholder: selectedDoctor?.clinicName == null,
            );
          },
        ),
        const SizedBox(height: 16),
        const _Label('المريض'),
        BlocBuilder<PatientsCubit, PatientsState>(
          builder: (context, state) {
            final patients = state is PatientsLoaded ? state.patients : null;
            return CaseLookupDropdown(
              value: patientId,
              icon: Icons.personal_injury_outlined,
              hintText: state is PatientsLoading
                  ? 'جارٍ تحميل المرضى...'
                  : 'اختر المريض',
              items: patients
                  ?.map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.fullName),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                PatientModel? patient;
                if (id != null && patients != null) {
                  for (final p in patients) {
                    if (p.id == id) {
                      patient = p;
                      break;
                    }
                  }
                }
                onPatientChanged(id, patient);
              },
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
        _DatePickerField(
          value: dueDate,
          hintText: 'اختر تاريخ التسليم (اختياري)',
          onTap: onPickDueDate,
        ),
        const SizedBox(height: 16),
        const _Label('تاريخ الاستلام'),
        _DatePickerField(
          value: receivedAt,
          hintText: 'اختر تاريخ استلام الحالة (اختياري)',
          onTap: onPickReceivedAt,
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

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.value,
    required this.hintText,
    required this.onTap,
  });

  final DateTime? value;
  final String hintText;
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
            const Icon(
              Icons.event_outlined,
              color: AppColorsManger.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              value == null
                  ? hintText
                  : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColorsManger.moreLightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColorsManger.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: isPlaceholder
                  ? AppTextStyles.font14RegularSecondary
                  : AppTextStyles.font14MediumText,
            ),
          ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsManger.moreLightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColorsManger.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ما في أطباء مسجّلين بعد — لازم تضيف طبيب أولاً',
                  style: AppTextStyles.font14RegularSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
