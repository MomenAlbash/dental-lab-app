import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
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

  // Not `showGlassBottomSheet` here: this sheet drives its own
  // DraggableScrollableSheet, so the glass surface is applied inside the
  // draggable (below) rather than around it.
  final result = await showModalBottomSheet<PatientFiltersModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.25),
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
      PatientFiltersModel(
        doctorId: _doctorId,
        clinicId: _clinicId,
        gender: _gender,
      ),
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
          return GlassSheetSurface(
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
                          style: AppTextStyles.font18MediumText.copyWith(
                            color: context.glass.onGlass,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearAll,
                        child: const Text('مسح الكل'),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: context.glass.strokeColor),
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
                            if (state is! DoctorsLoaded) {
                              return const GlassFieldSkeleton();
                            }
                            return CaseLookupDropdown(
                              value: _doctorId,
                              icon: Icons.medical_services_outlined,
                              hintText: 'كل الأطباء',
                              items: state.doctors
                                  .map(
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
                            if (state is! ClinicsLoaded) {
                              return const GlassFieldSkeleton();
                            }
                            return CaseLookupDropdown(
                              value: _clinicId,
                              icon: Icons.local_hospital_outlined,
                              hintText: 'كل العيادات',
                              items: state.clinics
                                  .map(
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
        child: Text(
          text,
          style: AppTextStyles.font14MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
      ),
    );
  }
}
