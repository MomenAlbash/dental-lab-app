import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_state.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_filters_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the filters sheet and applies the result to the [DoctorsCubit]
/// found above [context]. The sheet's own lookups (clinic/city) get fresh
/// cubit instances since a modal-sheet route isn't a descendant of the
/// page's provider tree.
Future<void> openDoctorFiltersSheet(BuildContext context) async {
  final doctorsCubit = context.read<DoctorsCubit>();

  // Not `showGlassBottomSheet` here: this sheet drives its own
  // DraggableScrollableSheet, so the glass surface is applied inside the
  // draggable (below) rather than around it.
  final result = await showModalBottomSheet<DoctorFiltersModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ClinicsCubit>()..getClinics()),
        BlocProvider(create: (_) => getIt<CitiesCubit>()..getCities()),
      ],
      child: DoctorFiltersSheet(initial: doctorsCubit.filters),
    ),
  );

  if (result != null) {
    doctorsCubit.applyFilters(result);
  }
}

/// The doctors filter sheet — shown via `showModalBottomSheet`. Pops with
/// the chosen [DoctorFiltersModel] on "تطبيق الفلاتر", or `null` if
/// dismissed. Requires [ClinicsCubit] and [CitiesCubit] in the tree (the
/// caller provides fresh instances since the sheet is a separate route).
class DoctorFiltersSheet extends StatefulWidget {
  const DoctorFiltersSheet({super.key, required this.initial});

  final DoctorFiltersModel initial;

  @override
  State<DoctorFiltersSheet> createState() => _DoctorFiltersSheetState();
}

class _DoctorFiltersSheetState extends State<DoctorFiltersSheet> {
  late String? _clinicId = widget.initial.clinicId;
  late String? _cityId = widget.initial.cityId;
  late DoctorGender? _gender = widget.initial.gender;

  void _clearAll() {
    setState(() {
      _clinicId = null;
      _cityId = null;
      _gender = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      DoctorFiltersModel(clinicId: _clinicId, cityId: _cityId, gender: _gender),
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
                          'تصفية الدكاترة',
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
                            for (final g in DoctorGender.values)
                              ChoiceChip(
                                label: Text(g.arabicLabel),
                                selected: _gender == g,
                                onSelected: (_) => setState(() => _gender = g),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const _Label('العيادة'),
                        BlocBuilder<ClinicsCubit, ClinicsState>(
                          builder: (context, state) {
                            // A shimmering placeholder the same size as the
                            // control it replaces, so nothing jumps when the
                            // options arrive.
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
                        const SizedBox(height: 20),
                        const _Label('المدينة'),
                        BlocBuilder<CitiesCubit, CitiesState>(
                          builder: (context, state) {
                            if (state is! CitiesLoaded) {
                              return const GlassFieldSkeleton();
                            }
                            return CaseLookupDropdown(
                              value: _cityId,
                              icon: Icons.location_city_outlined,
                              hintText: 'كل المدن',
                              items: state.cities
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name ?? '—'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _cityId = v),
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
