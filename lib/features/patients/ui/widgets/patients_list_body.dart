import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_state.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patient_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Whether a patient has any cases on record.
enum PatientCaseFilter { all, linked, unlinked }

/// The patients list body — reads the shared [PatientsCubit] from the page.
///
/// [caseFilter] is owned by the page (alongside [PatientCaseFilterStrip],
/// which sits above this widget right under the search field) so the filter
/// choice and its counts stay put in one spot on screen instead of living
/// inside — and disappearing along with — this widget's loading states.
class PatientsListBody extends StatefulWidget {
  const PatientsListBody({
    super.key,
    required this.caseFilter,
    this.scrollController,
  });

  final PatientCaseFilter caseFilter;

  /// Owned by the page, which watches it to collapse the add button.
  final ScrollController? scrollController;

  @override
  State<PatientsListBody> createState() => _PatientsListBodyState();
}

class _PatientsListBodyState extends State<PatientsListBody> {
  /// Kept so a refresh shows the existing rows instead of the skeleton —
  /// otherwise the RefreshIndicator gets unmounted mid-pull along with the
  /// list it belongs to.
  List<PatientModel>? _lastPatients;

  List<PatientModel> _applyCaseFilter(List<PatientModel> patients) {
    return switch (widget.caseFilter) {
      PatientCaseFilter.all => patients,
      PatientCaseFilter.linked =>
        patients.where((patient) => patient.caseCount > 0).toList(),
      PatientCaseFilter.unlinked =>
        patients.where((patient) => patient.caseCount == 0).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientsCubit, PatientsState>(
      builder: (context, state) {
        if (state is PatientsLoaded) _lastPatients = state.patients;

        final patients = switch (state) {
          PatientsLoaded(:final patients) => patients,
          PatientsLoading() => _lastPatients,
          _ => null,
        };

        return AnimatedSwitcher(
          duration: AppMotion.base,
          switchInCurve: AppMotion.enter,
          child: switch ((state, patients)) {
            (_, final List<PatientModel> loaded) =>
              loaded.isEmpty
                  ? const _Empty(key: ValueKey('patients-empty'))
                  : _PatientsRows(
                      key: const ValueKey('patients-loaded'),
                      filtered: _applyCaseFilter(loaded),
                      caseFilter: widget.caseFilter,
                      scrollController: widget.scrollController,
                    ),
            (PatientsError(:final message), null) => Center(
              key: const ValueKey('patients-error'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: context.glass.onGlassMuted,
                  ),
                ),
              ),
            ),
            _ => const Padding(
              key: ValueKey('patients-loading'),
              padding: EdgeInsets.only(top: 24),
              child: GlassListSkeleton(),
            ),
          },
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: glass.surfaceGradient,
                    border: Border.all(color: glass.strokeColor),
                  ),
                  child: Icon(
                    Icons.groups_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد مرضى بعد',
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول مريض بالضغط على زر الإضافة',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: AppMotion.base,
          curve: AppMotion.enter,
        );
  }
}

/// The (case-filtered) rows, or a message explaining why the filter hid
/// everything.
class _PatientsRows extends StatelessWidget {
  const _PatientsRows({
    super.key,
    required this.filtered,
    required this.caseFilter,
    this.scrollController,
  });

  final List<PatientModel> filtered;
  final PatientCaseFilter caseFilter;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (filtered.isEmpty) return _FilteredEmpty(caseFilter: caseFilter);

    return AdaptiveCollection<PatientModel>(
      items: filtered,
      scrollController: scrollController,
      onRefresh: () => context.read<PatientsCubit>().getPatients(),
      itemBuilder: (context, patient, _) => PatientListItemWidget(
        fullName: patient.fullName,
        doctorName: patient.doctorName ?? '',
        clinicName: patient.clinicName ?? '',
        caseCount: patient.caseCount,
        gender: patient.gender,
        phoneNumber: patient.phoneNumber,
        heroTag: 'patient-avatar-${patient.id}',
        onTap: () async {
          await context.push(Routes.patientDetailScreen, extra: patient.id);
          if (context.mounted) {
            context.read<PatientsCubit>().getPatients();
          }
        },
      ),
    );
  }
}

/// Shown when the case-link filter hides every patient — distinct from the
/// "no patients at all" empty state, so the user knows a filter is active.
class _FilteredEmpty extends StatelessWidget {
  const _FilteredEmpty({required this.caseFilter});

  final PatientCaseFilter caseFilter;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final message = switch (caseFilter) {
      PatientCaseFilter.linked => 'لا يوجد مرضى مرتبطين بحالة',
      PatientCaseFilter.unlinked => 'لا يوجد مرضى غير مرتبطين بحالة',
      PatientCaseFilter.all => 'لا يوجد مرضى',
    };

    return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: glass.surfaceGradient,
                    border: Border.all(color: glass.strokeColor),
                  ),
                  child: Icon(
                    Icons.filter_alt_off_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'اضغط "الكل" لعرض الجميع',
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: AppMotion.base,
          curve: AppMotion.enter,
        );
  }
}

/// The case-link filter strip — three counters that double as the filter
/// control. Lives at the page level, directly under the search field, so it
/// stays anchored there instead of toggling in and out with the list body's
/// loading/loaded/error states below it.
///
/// Keeps its own last-known count cache for the same reason as the body: a
/// refresh must not blank the strip out mid-pull.
class PatientCaseFilterStrip extends StatefulWidget {
  const PatientCaseFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PatientCaseFilter selected;
  final ValueChanged<PatientCaseFilter> onSelected;

  @override
  State<PatientCaseFilterStrip> createState() => _PatientCaseFilterStripState();
}

class _PatientCaseFilterStripState extends State<PatientCaseFilterStrip> {
  List<PatientModel>? _lastPatients;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientsCubit, PatientsState>(
      builder: (context, state) {
        if (state is PatientsLoaded) _lastPatients = state.patients;
        final patients = _lastPatients;

        // Nothing to filter yet (first load, or genuinely no patients) — the
        // page's empty state already explains that, so the strip stays out
        // of the way rather than showing three zeroes.
        if (patients == null || patients.isEmpty) {
          return const SizedBox.shrink();
        }

        final linked = patients
            .where((patient) => patient.caseCount > 0)
            .length;

        final tiles = <(PatientCaseFilter, String, int, Color)>[
          (
            PatientCaseFilter.all,
            'الكل',
            patients.length,
            Theme.of(context).colorScheme.primary,
          ),
          (PatientCaseFilter.linked, 'مرتبط بحالة', linked, context.glass.info),
          (
            PatientCaseFilter.unlinked,
            'غير مرتبط',
            patients.length - linked,
            context.glass.onGlassMuted,
          ),
        ];

        return Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryTile(
                  key: ValueKey('patient-case-filter-${tiles[i].$1.name}'),
                  label: tiles[i].$2,
                  count: tiles[i].$3,
                  color: tiles[i].$4,
                  isSelected: widget.selected == tiles[i].$1,
                  onTap: () => widget.onSelected(tiles[i].$1),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool isSelected;
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
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: isSelected ? null : glass.surfaceGradient,
            color: isSelected ? color.withValues(alpha: 0.16) : null,
            border: Border.all(
              color: isSelected ? color : glass.strokeColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: AppTextStyles.font20BoldText.copyWith(
                  color: isSelected ? color : glass.onGlass,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: isSelected ? color : glass.onGlassMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
