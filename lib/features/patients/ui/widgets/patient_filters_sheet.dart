import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_filters_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_gender.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the filters sheet and applies the result to the [PatientsCubit]
/// found above [context]. The sheet's own lookups (doctor/clinic) get fresh
/// cubit instances since a modal-sheet route isn't a descendant of the
/// page's provider tree.
Future<void> openPatientFiltersSheet(BuildContext context) async {
  final patientsCubit = context.read<PatientsCubit>();

  final result = await showModalBottomSheet<PatientFiltersModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DoctorsCubit>()..getDoctors()),
        BlocProvider(create: (_) => getIt<ClinicsCubit>()..getClinics()),
      ],
      child: PatientFiltersSheet(initial: patientsCubit.filters),
    ),
  );

  if (result != null) {
    await patientsCubit.applyFilters(result);
  }
}

/// The patients filter sheet — shown via `showModalBottomSheet`. Pops with
/// the chosen [PatientFiltersModel] on "تطبيق الفلاتر", or `null` if
/// dismissed. Requires [DoctorsCubit] and [ClinicsCubit] in the tree (the
/// caller provides fresh instances since the sheet is a separate route).
class PatientFiltersSheet extends StatefulWidget {
  const PatientFiltersSheet({super.key, required this.initial});

  final PatientFiltersModel initial;

  @override
  State<PatientFiltersSheet> createState() => _PatientFiltersSheetState();
}

class _PatientFiltersSheetState extends State<PatientFiltersSheet> {
  late String? _doctorId = widget.initial.doctorId;
  late String? _clinicId = widget.initial.clinicId;
  late PatientGender? _gender = widget.initial.gender;

  void _clearAll() {
    setState(() {
      _doctorId = null;
      _clinicId = null;
      _gender = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      PatientFiltersModel(doctorId: _doctorId, clinicId: _clinicId, gender: _gender),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the sheet (and whichever field the user is typing into) above
    // the keyboard instead of letting the keyboard cover it.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColorsManger.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                    Expanded(
                      child: Text(
                        'تصفية المرضى',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.font18MediumText,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('مسح الكل'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColorsManger.divider),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Label('الجنس'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('الكل'),
                            selected: _gender == null,
                            onSelected: (_) => setState(() => _gender = null),
                          ),
                          for (final g in PatientGender.values)
                            ChoiceChip(
                              label: Text(g.arabicLabel),
                              selected: _gender == g,
                              onSelected: (_) => setState(() => _gender = g),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _Label('الطبيب'),
                      BlocBuilder<DoctorsCubit, DoctorsState>(
                        builder: (context, state) {
                          final doctors = state is DoctorsLoaded
                              ? state.doctors
                              : null;
                          return CaseLookupDropdown(
                            value: _doctorId,
                            icon: Icons.medical_services_outlined,
                            hintText: state is DoctorsLoading
                                ? 'جارٍ تحميل الأطباء...'
                                : 'كل الأطباء',
                            items: doctors
                                ?.map(
                                  (d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Text(d.fullName),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _doctorId = v),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const _Label('العيادة'),
                      BlocBuilder<ClinicsCubit, ClinicsState>(
                        builder: (context, state) {
                          final clinics = state is ClinicsLoaded
                              ? state.clinics
                              : null;
                          return CaseLookupDropdown(
                            value: _clinicId,
                            icon: Icons.local_hospital_outlined,
                            hintText: state is ClinicsLoading
                                ? 'جارٍ تحميل العيادات...'
                                : 'كل العيادات',
                            items: clinics
                                ?.map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _clinicId = v),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColorsManger.primary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('تطبيق الفلاتر'),
                  ),
                ),
              ),
            ],
            ),
          );
        },
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
