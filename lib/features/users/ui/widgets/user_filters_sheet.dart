import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_state.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratories/laboratories_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratories/laboratories_state.dart';
import 'package:dental_lab_app/features/users/data/models/user_filters_model.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/logic/users/users_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the filters sheet and applies the result to the [UsersCubit] found
/// above [context]. The sheet's own lookups (laboratory/doctor/employee) get
/// fresh cubit instances since a modal-sheet route isn't a descendant of the
/// page's provider tree.
Future<void> openUserFiltersSheet(BuildContext context) async {
  final usersCubit = context.read<UsersCubit>();

  final result = await showModalBottomSheet<UserFiltersModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<LaboratoriesCubit>()..getLaboratories(),
        ),
        BlocProvider(create: (_) => getIt<DoctorsCubit>()..getDoctors()),
        BlocProvider(create: (_) => getIt<EmployeesCubit>()..getEmployees()),
      ],
      child: UserFiltersSheet(initial: usersCubit.filters),
    ),
  );

  if (result != null) {
    await usersCubit.applyFilters(result);
  }
}

/// The users filter sheet — shown via `showModalBottomSheet`. Pops with the
/// chosen [UserFiltersModel] on "تطبيق الفلاتر", or `null` if dismissed.
/// Requires [LaboratoriesCubit], [DoctorsCubit] and [EmployeesCubit] in the
/// tree (the caller provides fresh instances since the sheet is a separate
/// route).
class UserFiltersSheet extends StatefulWidget {
  const UserFiltersSheet({super.key, required this.initial});

  final UserFiltersModel initial;

  @override
  State<UserFiltersSheet> createState() => _UserFiltersSheetState();
}

class _UserFiltersSheetState extends State<UserFiltersSheet> {
  late String? _laboratoryId = widget.initial.laboratoryId;
  late UserType? _type = widget.initial.type;
  late String? _doctorId = widget.initial.doctorId;
  late String? _employeeId = widget.initial.employeeId;

  void _clearAll() {
    setState(() {
      _laboratoryId = null;
      _type = null;
      _doctorId = null;
      _employeeId = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      UserFiltersModel(
        laboratoryId: _laboratoryId,
        type: _type,
        doctorId: _doctorId,
        employeeId: _employeeId,
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
                          'تصفية المستخدمين',
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
                        const _Label('المخبر'),
                        BlocBuilder<LaboratoriesCubit, LaboratoriesState>(
                          builder: (context, state) {
                            if (state is! LaboratoriesLoaded) {
                              return const GlassFieldSkeleton();
                            }
                            return CaseLookupDropdown(
                              value: _laboratoryId,
                              icon: Icons.factory_outlined,
                              hintText: 'كل المخابر',
                              items: state.laboratories
                                  .map(
                                    (lab) => DropdownMenuItem(
                                      value: lab.id,
                                      child: Text(lab.name ?? '—'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _laboratoryId = v),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const _Label('نوع الحساب المرتبط'),
                        // A user is bound to either a doctor or an employee
                        // record, so only one lookup below applies at a
                        // time — this chip row picks which.
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('الكل'),
                              selected: _type == null,
                              onSelected: (_) => setState(() => _type = null),
                            ),
                            ChoiceChip(
                              label: const Text('موظف'),
                              selected: _type == UserType.employee,
                              onSelected: (_) =>
                                  setState(() => _type = UserType.employee),
                            ),
                            ChoiceChip(
                              label: const Text('طبيب'),
                              selected: _type == UserType.doctor,
                              onSelected: (_) =>
                                  setState(() => _type = UserType.doctor),
                            ),
                          ],
                        ),
                        if (_type == UserType.doctor) ...[
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
                                        child: Text(
                                          d.fullName.isEmpty ? '—' : d.fullName,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _doctorId = v),
                              );
                            },
                          ),
                        ],
                        if (_type == UserType.employee) ...[
                          const SizedBox(height: 20),
                          const _Label('الموظف'),
                          BlocBuilder<EmployeesCubit, EmployeesState>(
                            builder: (context, state) {
                              if (state is! EmployeesLoaded) {
                                return const GlassFieldSkeleton();
                              }
                              return CaseLookupDropdown(
                                value: _employeeId,
                                icon: Icons.badge_outlined,
                                hintText: 'كل الموظفين',
                                items: state.employees
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.id,
                                        child: Text(
                                          e.fullName.isEmpty ? '—' : e.fullName,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _employeeId = v),
                              );
                            },
                          ),
                        ],
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
