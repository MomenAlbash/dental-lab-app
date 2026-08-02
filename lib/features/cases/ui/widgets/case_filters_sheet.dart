import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_priority.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the filters sheet and applies the result to the [CasesCubit] found
/// above [context]. The sheet's own lookups (doctor/clinic) get fresh cubit
/// instances since a modal-sheet route isn't a descendant of the page's
/// provider tree.
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
/// Requires [DoctorsCubit] and [ClinicsCubit] in the tree (the caller
/// provides fresh instances since the sheet is a separate route).
class CaseFiltersSheet extends StatefulWidget {
  const CaseFiltersSheet({super.key, required this.initial});

  final CaseFiltersModel initial;

  @override
  State<CaseFiltersSheet> createState() => _CaseFiltersSheetState();
}

class _CaseFiltersSheetState extends State<CaseFiltersSheet> {
  late String? _doctorId = widget.initial.doctorId;
  late String? _clinicId = widget.initial.clinicId;
  
  late CasePriority? _priority = widget.initial.priority;
  late DateTime? _dueDateFrom = widget.initial.dueDateFrom;
  late DateTime? _dueDateTo = widget.initial.dueDateTo;

  void _clearAll() {
    setState(() {
      _doctorId = null;
      _clinicId = null;

      _priority = null;
      _dueDateFrom = null;
      _dueDateTo = null;
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = (isFrom ? _dueDateFrom : _dueDateTo) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _dueDateFrom = picked;
      } else {
        _dueDateTo = picked;
      }
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      CaseFiltersModel(
        doctorId: _doctorId,
        clinicId: _clinicId,

        priority: _priority,
        dueDateFrom: _dueDateFrom,
        dueDateTo: _dueDateTo,
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
              const Divider(height: 1, color: AppColorsManger.divider),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Label('الأولوية'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('الكل'),
                            selected: _priority == null,
                            onSelected: (_) =>
                                setState(() => _priority = null),
                          ),
                          for (final p in CasePriority.values)
                            ChoiceChip(
                              label: Text(p.arabicLabel),
                              selected: _priority == p,
                              onSelected: (_) => setState(() => _priority = p),
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
                      const SizedBox(height: 20),
                      const _Label('تاريخ التسليم'),
                      Row(
                        children: [
                          Expanded(
                            child: _DateChip(
                              value: _dueDateFrom,
                              hintText: 'من',
                              onTap: () => _pickDate(isFrom: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateChip(
                              value: _dueDateTo,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColorsManger.moreLightGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_outlined,
              size: 18,
              color: AppColorsManger.textSecondary,
            ),
            const SizedBox(width: 8),
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
