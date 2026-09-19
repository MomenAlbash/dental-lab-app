import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/users/data/repos/users_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Which doctors one login may see.
///
/// **Empty means unrestricted** — the absence of a narrowing, not a narrowing
/// to nothing. The sheet says so out loud, because the two readings differ by
/// everything and the control looks identical either way.
///
/// The scope is enforced server-side: every doctor, case and patient list the
/// app renders already arrives filtered for a scoped user. This screen decides
/// the rule; it does not implement it.
Future<bool> showDoctorScopeSheet(
  BuildContext context, {
  required String userId,
  required String userLabel,
}) async {
  final saved = await showGlassBottomSheet<bool>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<DoctorsCubit>()..getDoctors(),
      child: _DoctorScopeSheet(userId: userId, userLabel: userLabel),
    ),
  );
  return saved ?? false;
}

class _DoctorScopeSheet extends StatefulWidget {
  const _DoctorScopeSheet({required this.userId, required this.userLabel});

  final String userId;
  final String userLabel;

  @override
  State<_DoctorScopeSheet> createState() => _DoctorScopeSheetState();
}

class _DoctorScopeSheetState extends State<_DoctorScopeSheet> {
  final _searchController = TextEditingController();

  Set<String>? _selected;
  String? _error;
  bool _isBusy = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await getIt<UsersRepo>().getDoctorScope(widget.userId);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() => _error = failure.errorMessage),
      (ids) => setState(() => _selected = ids.toSet()),
    );
  }

  Future<void> _save() async {
    final selected = _selected;
    if (selected == null) return;

    setState(() => _isBusy = true);

    final result = await getIt<UsersRepo>().setDoctorScope(
      userId: widget.userId,
      doctorIds: selected.toList(),
    );
    if (!mounted) return;

    setState(() => _isBusy = false);

    result.fold(
      (failure) =>
          showToast(message: failure.errorMessage, state: ToastState.error),
      (_) {
        showToast(message: 'تم حفظ نطاق الأطباء', state: ToastState.success);
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final selected = _selected;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'نطاق الأطباء',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            Text(
              widget.userLabel,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (selected?.isEmpty ?? true)
                    ? glass.info.withValues(alpha: 0.12)
                    : glass.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.glass),
              ),
              child: Text(
                (selected?.isEmpty ?? true)
                    ? 'لم يُحدَّد أي طبيب — المستخدم يرى جميع الأطباء'
                    : 'المستخدم يرى ${selected!.length} طبيباً فقط',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: (selected?.isEmpty ?? true)
                      ? glass.info
                      : glass.warning,
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.error,
                ),
              ),
            ] else if (selected == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              const SizedBox(height: AppSpacing.md),
              AppTextFormField(
                controller: _searchController,
                hintText: 'ابحث عن طبيب…',
                prefixIcon: Icon(Icons.search, color: glass.onGlassMuted),
                validator: (_) => null,
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
              const SizedBox(height: AppSpacing.sm),

              if (selected.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    // The only way back to unrestricted: an empty set lifts
                    // the narrowing entirely.
                    onPressed: () => setState(selected.clear),
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('إزالة التقييد (يرى الجميع)'),
                  ),
                ),

              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.4,
                child: BlocBuilder<DoctorsCubit, DoctorsState>(
                  builder: (context, state) {
                    if (state is! DoctorsLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final doctors = [
                      for (final doctor in state.doctors)
                        if (_query.isEmpty ||
                            doctor.fullName.toLowerCase().contains(
                              _query.toLowerCase(),
                            ))
                          doctor,
                    ];

                    if (doctors.isEmpty) {
                      return Center(
                        child: Text(
                          'لا يوجد طبيب بهذا الاسم',
                          style: AppTextStyles.font12RegularHint.copyWith(
                            color: glass.onGlassMuted,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final DoctorModel doctor = doctors[index];
                        return CheckboxListTile(
                          dense: true,
                          value: selected.contains(doctor.id),
                          title: Text(doctor.fullName),
                          onChanged: (value) => setState(() {
                            if (value ?? false) {
                              selected.add(doctor.id);
                            } else {
                              selected.remove(doctor.id);
                            }
                          }),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              CustomButtonWidget(
                buttonText: 'حفظ',
                onPressed: _isBusy ? null : _save,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
