import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_state.dart';
import 'package:dental_lab_app/features/case_stages/logic/case_stages/case_stages_cubit.dart';
import 'package:dental_lab_app/features/case_stages/logic/case_stages/case_stages_state.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_state.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratories/laboratories_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratories/laboratories_state.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the filters sheet and applies the result to the [CasesCubit] found
/// above [context]. The sheet's own lookups (doctor, clinic, patient,
/// priority, stage) get fresh cubit instances since a modal-sheet route isn't
/// a descendant of the page's provider tree.
Future<void> openCaseFiltersSheet(BuildContext context) async {
  final casesCubit = context.read<CasesCubit>();

  final result = await showModalBottomSheet<CaseFiltersModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DoctorsCubit>()..getDoctors()),
        BlocProvider(create: (_) => getIt<ClinicsCubit>()..getClinics()),
        BlocProvider(create: (_) => getIt<PatientsCubit>()..getPatients()),
        // The active ones only — the filter offers exactly what the case form
        // can file a case under, so the two never disagree.
        BlocProvider(
          create: (_) => getIt<CasePrioritiesCubit>()..getCasePriorities(),
        ),
        BlocProvider(create: (_) => getIt<CaseStagesCubit>()..getCaseStages()),
        BlocProvider(create: (_) => getIt<CitiesCubit>()..getCities()),
        // Only fetched for a user who may actually browse across branches;
        // for everyone else the server pins the list to the header's lab, so
        // the control is not offered and the request would be wasted.
        if (getIt<SessionCubit>().state.canBrowseAllLaboratories)
          BlocProvider(
            create: (_) => getIt<LaboratoriesCubit>()..getLaboratories(),
          ),
      ],
      child: CaseFiltersSheet(initial: casesCubit.filters),
    ),
  );

  if (result != null) {
    await casesCubit.applyFilters(result);
  }
}

/// The cases filter sheet — shown via `showModalBottomSheet`. Pops with the
/// chosen [CaseFiltersModel] on "تطبيق الفلاتر", or `null` if dismissed.
/// Requires [DoctorsCubit], [ClinicsCubit], [PatientsCubit] and
/// [CasePrioritiesCubit] in the tree (the caller provides fresh instances
/// since the sheet is a separate route).
class CaseFiltersSheet extends StatefulWidget {
  const CaseFiltersSheet({super.key, required this.initial});

  final CaseFiltersModel initial;

  @override
  State<CaseFiltersSheet> createState() => _CaseFiltersSheetState();
}

class _CaseFiltersSheetState extends State<CaseFiltersSheet> {
  late String? _doctorId = widget.initial.doctorId;
  late String? _clinicId = widget.initial.clinicId;
  late String? _patientId = widget.initial.patientId;
  late String? _patientName = widget.initial.patientName;

  late String? _priorityId = widget.initial.priorityId;
  late String? _priorityName = widget.initial.priorityName;

  /// Several stages at once: the API takes `StageIds` repeatedly, and "still
  /// in review" is usually more than one of the lab's stages.
  late Set<String> _stageIds = {...widget.initial.stageIds};

  /// Several labs at once — browsing branches side by side is the point of
  /// the filter. Empty means "just the active one".
  late Set<String> _laboratoryIds = {...widget.initial.laboratoryIds};

  /// Cities are narrowed client-side, so the names ride along to be shown
  /// back in the sheet without another lookup.
  late Set<String> _cityIds = {...widget.initial.cityIds};
  late Set<String> _cityNames = {...widget.initial.cityNames};

  late DateTime? _receivedFrom = widget.initial.receivedFrom;
  late DateTime? _receivedTo = widget.initial.receivedTo;

  void _clearAll() {
    setState(() {
      _doctorId = null;
      _clinicId = null;
      _patientId = null;
      _patientName = null;
      _priorityId = null;
      _priorityName = null;
      _stageIds = {};
      _laboratoryIds = {};
      _cityIds = {};
      _cityNames = {};
      _receivedFrom = null;
      _receivedTo = null;
    });
  }

  void _toggleStage(String id) {
    setState(() {
      if (!_stageIds.remove(id)) _stageIds.add(id);
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = (isFrom ? _receivedFrom : _receivedTo) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _receivedFrom = picked;
      } else {
        _receivedTo = picked;
      }
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      CaseFiltersModel(
        doctorId: _doctorId,
        clinicId: _clinicId,
        patientId: _patientId,
        patientName: _patientName,
        priorityId: _priorityId,
        priorityName: _priorityName,
        stageIds: _stageIds,
        laboratoryIds: _laboratoryIds,
        cityIds: _cityIds,
        cityNames: _cityNames,
        receivedFrom: _receivedFrom,
        receivedTo: _receivedTo,
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
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
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
                          'تصفية الحالات',
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
                Divider(height: 1, color: context.glass.strokeColor),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Label('الأولوية'),
                        // Chips still, but over the lab's own priorities rather
                        // than a fixed four — the list is short enough that a
                        // dropdown would be a step backwards.
                        BlocBuilder<CasePrioritiesCubit, CasePrioritiesState>(
                          builder: (context, state) {
                            final priorities = state is CasePrioritiesLoaded
                                ? state.priorities
                                : const [];

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('الكل'),
                                  selected: _priorityId == null,
                                  onSelected: (_) => setState(() {
                                    _priorityId = null;
                                    _priorityName = null;
                                  }),
                                ),
                                for (final p in priorities)
                                  ChoiceChip(
                                    label: Text(p.displayName),
                                    selected: _priorityId == p.id,
                                    onSelected: (_) => setState(() {
                                      _priorityId = p.id;
                                      _priorityName = p.displayName;
                                    }),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const _Label('المرحلة'),
                        // The lab's own stages, grouped under the doctor-facing
                        // category they belong to. Multi-select: "still in
                        // review" is usually several stages, and the API takes
                        // StageIds repeatedly.
                        BlocBuilder<CaseStagesCubit, CaseStagesState>(
                          builder: (context, state) {
                            if (state is CaseStagesError) {
                              return Text(
                                state.message,
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: context.glass.onGlassMuted,
                                ),
                              );
                            }
                            if (state is! CaseStagesLoaded) {
                              return Text(
                                'جارٍ تحميل المراحل...',
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: context.glass.onGlassMuted,
                                ),
                              );
                            }
                            if (state.stages.isEmpty) {
                              return Text(
                                'لم يعرّف المخبر مراحل بعد',
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: context.glass.onGlassMuted,
                                ),
                              );
                            }

                            // Flat, not grouped: the API carries no
                            // doctor-facing category on a case stage any more
                            // (the field was retired), so every stage sits in
                            // the lab's own catalogue order instead.
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final stage in state.stages)
                                  FilterChip(
                                    // The catalogue already counts the cases
                                    // per stage, so the chip says how much it
                                    // would return.
                                    label: Text(
                                      stage.caseCount > 0
                                          ? '${stage.displayName} (${stage.caseCount})'
                                          : stage.displayName,
                                    ),
                                    selected: _stageIds.contains(stage.id),
                                    onSelected: (_) => _toggleStage(stage.id),
                                  ),
                              ],
                            );
                          },
                        ),
                        // Only for a user the server will actually honour it
                        // for — see `canBrowseAllLaboratories`.
                        if (getIt<SessionCubit>()
                            .state
                            .canBrowseAllLaboratories) ...[
                          const SizedBox(height: 20),
                          const _Label('المخبر'),
                          BlocBuilder<LaboratoriesCubit, LaboratoriesState>(
                            builder: (context, state) {
                              if (state is! LaboratoriesLoaded) {
                                return const SizedBox.shrink();
                              }
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final lab in state.laboratories)
                                    FilterChip(
                                      label: Text(lab.name ?? '—'),
                                      selected: _laboratoryIds.contains(lab.id),
                                      onSelected: (_) => setState(() {
                                        if (!_laboratoryIds.remove(lab.id)) {
                                          _laboratoryIds.add(lab.id);
                                        }
                                      }),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 20),
                        const _Label('المدينة'),
                        // Said outright: this one narrows the rows already
                        // fetched, because `GET /Cases` takes no city
                        // parameter. A user who expects it to search the whole
                        // table would otherwise read a short list as "there
                        // are no more".
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'يُطبَّق على النتائج المعروضة فقط',
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: context.glass.onGlassMuted,
                            ),
                          ),
                        ),
                        BlocBuilder<CitiesCubit, CitiesState>(
                          builder: (context, state) {
                            if (state is! CitiesLoaded) {
                              return const SizedBox.shrink();
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final city in state.cities)
                                  FilterChip(
                                    label: Text(city.name ?? '—'),
                                    selected: _cityIds.contains(city.id),
                                    onSelected: (_) => setState(() {
                                      if (_cityIds.remove(city.id)) {
                                        _cityNames.remove(city.name ?? '');
                                      } else {
                                        _cityIds.add(city.id);
                                        _cityNames.add(city.name ?? '');
                                      }
                                    }),
                                  ),
                              ],
                            );
                          },
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
                        const SizedBox(height: 20),
                        const _Label('المريض'),
                        BlocBuilder<PatientsCubit, PatientsState>(
                          builder: (context, state) {
                            final patients = state is PatientsLoaded
                                ? state.patients
                                : null;
                            return CaseLookupDropdown(
                              value: _patientId,
                              icon: Icons.personal_injury_outlined,
                              hintText: state is PatientsLoading
                                  ? 'جارٍ تحميل المرضى...'
                                  : 'كل المرضى',
                              items: patients
                                  ?.map(
                                    (p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text(p.fullName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (id) {
                                String? name;
                                if (id != null && patients != null) {
                                  for (final p in patients) {
                                    if (p.id == id) {
                                      name = p.fullName;
                                      break;
                                    }
                                  }
                                }
                                setState(() {
                                  _patientId = id;
                                  _patientName = name;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const _Label('تاريخ الاستلام'),
                        Row(
                          children: [
                            Expanded(
                              child: _DateChip(
                                value: _receivedFrom,
                                hintText: 'من',
                                onTap: () => _pickDate(isFrom: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DateChip(
                                value: _receivedTo,
                                hintText: 'إلى',
                                onTap: () => _pickDate(isFrom: false),
                              ),
                            ),
                          ],
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
        child: Text(text, style: AppTextStyles.font14MediumText),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
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
      borderRadius: BorderRadius.circular(AppRadius.glass),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: context.glass.surfaceGradient,
          borderRadius: BorderRadius.circular(AppRadius.glass),
          border: Border.all(color: context.glass.strokeColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_outlined,
              size: 18,
              color: context.glass.onGlassMuted,
            ),
            const SizedBox(width: 8),
            Text(
              value == null
                  ? hintText
                  : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}',
              style: value == null
                  ? AppTextStyles.font14RegularSecondary.copyWith(
                      color: context.glass.onGlassMuted,
                    )
                  : AppTextStyles.font14MediumText.copyWith(
                      color: context.glass.onGlass,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
