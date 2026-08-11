import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_summary_strip.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Which subset of the loaded doctors the list is showing.
enum DoctorStatusFilter { all, active, inactive }

/// The doctors list: a summary strip that doubles as a status filter, the
/// search field, then the rows.
///
/// The counts are not decoration — each tile is the control for its own slice,
/// so "show me the paused doctors" is one tap instead of a trip through the
/// filter sheet.
class DoctorsListView extends StatefulWidget {
  const DoctorsListView({
    super.key,
    required this.doctors,
    required this.searchController,
    required this.searchQuery,
    required this.onDelete,
    this.scrollController,
  });

  /// Already filtered by the search query and the filter sheet.
  final List<DoctorModel> doctors;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<DoctorModel> onDelete;

  /// Owned by the page, which watches it to collapse the add button.
  final ScrollController? scrollController;

  @override
  State<DoctorsListView> createState() => _DoctorsListViewState();
}

class _DoctorsListViewState extends State<DoctorsListView> {
  DoctorStatusFilter _status = DoctorStatusFilter.all;

  List<DoctorModel> get _visible {
    final filtered = switch (_status) {
      DoctorStatusFilter.all => widget.doctors,
      DoctorStatusFilter.active =>
        widget.doctors.where((doctor) => doctor.isActive).toList(),
      DoctorStatusFilter.inactive =>
        widget.doctors.where((doctor) => !doctor.isActive).toList(),
    };

    // Registrations waiting on a decision come first — they are the only rows
    // that need the user to act, and buried in the list they sit unanswered.
    // Partitioned rather than sorted: List.sort is not stable, so a comparator
    // would quietly reshuffle everything else out of the server's order.
    return [
      ...filtered.where((doctor) => doctor.isPending),
      ...filtered.where((doctor) => !doctor.isPending),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = widget.doctors
        .where((doctor) => doctor.isActive)
        .length;
    final visible = _visible;

    return Builder(
      builder: (context) {
        // The header keeps a phone-ish inset on a phone and a roomier one
        // from tablet up; the rows themselves are laid out by
        // AdaptiveCollection, which fills the width rather than capping it.
        final horizontal =
            AdaptiveLayout.of(context) == AdaptiveFormFactor.mobile
            ? AppSpacing.lg
            : AppSpacing.xl;

        return Column(
          children: [
            Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    AppSpacing.md,
                    horizontal,
                    AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      GlassSummaryStrip<DoctorStatusFilter>(
                        tiles: [
                          GlassSummaryTileData(
                            value: DoctorStatusFilter.all,
                            label: 'الكل',
                            count: widget.doctors.length,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          GlassSummaryTileData(
                            value: DoctorStatusFilter.active,
                            label: 'نشط',
                            count: activeCount,
                            color: context.glass.success,
                          ),
                          GlassSummaryTileData(
                            value: DoctorStatusFilter.inactive,
                            label: 'موقوف',
                            count: widget.doctors.length - activeCount,
                            color: context.glass.onGlassMuted,
                          ),
                        ],
                        selected: _status,
                        onSelected: (value) => setState(() => _status = value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextFormField(
                        controller: widget.searchController,
                        hintText: 'ابحث باسم الدكتور...',
                        // No explicit colour: the field tints it on focus.
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: widget.searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'مسح البحث',
                                onPressed: () =>
                                    widget.searchController.clear(),
                                icon: Icon(
                                  Icons.close,
                                  color: context.glass.onGlassMuted,
                                ),
                              ),
                        validator: (_) => null,
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: AppMotion.base)
                .slideY(
                  begin: -0.12,
                  duration: AppMotion.base,
                  curve: AppMotion.enter,
                ),
            Expanded(
              child: visible.isEmpty
                  ? _EmptyState(
                      searchQuery: widget.searchQuery,
                      status: _status,
                    )
                  : AdaptiveCollection<DoctorModel>(
                      items: visible,
                      scrollController: widget.scrollController,
                      onRefresh: () =>
                          context.read<DoctorsCubit>().getDoctors(),
                      itemBuilder: (context, doctor, _) => DoctorListItemWidget(
                        fullName: doctor.fullName,
                        initials: doctor.initials,
                        phoneNumber: doctor.phoneNumber ?? '',
                        clinicName: doctor.clinicName ?? '',
                        isActive: doctor.isActive,
                        approvalStatus: doctor.approvalStatus,
                        heroTag: 'doctor-avatar-${doctor.id}',
                        // Refetch on return: the detail screen has its
                        // own edit action, so a doctor can come back
                        // changed (status, clinic, name). Without this
                        // the list keeps rendering the stale copy —
                        // e.g. a doctor just paused still counted as
                        // active in the summary strip.
                        onTap: () async {
                          await context.push(
                            Routes.doctorDetailScreen,
                            extra: doctor.id,
                          );
                          if (context.mounted) {
                            context.read<DoctorsCubit>().getDoctors();
                          }
                        },
                        onEdit: () async {
                          await context.push(
                            Routes.doctorFormScreen,
                            extra: doctor,
                          );
                          if (context.mounted) {
                            context.read<DoctorsCubit>().getDoctors();
                          }
                        },
                        onDelete: () => widget.onDelete(doctor),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searchQuery, required this.status});

  final String searchQuery;
  final DoctorStatusFilter status;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isSearching = searchQuery.isNotEmpty;
    final isFiltered = status != DoctorStatusFilter.all;

    final (IconData icon, String title, String hint) = switch ((
      isSearching,
      isFiltered,
    )) {
      (true, _) => (
        Icons.search_off,
        'لا توجد نتائج',
        'جرّب اسماً آخر أو امسح البحث',
      ),
      (false, true) => (
        Icons.filter_alt_off_outlined,
        'لا يوجد دكاترة بهذه الحالة',
        'اضغط "الكل" لعرض الجميع',
      ),
      _ => (
        Icons.person_add_alt,
        'لا يوجد دكاترة بعد',
        'أضف أول دكتور بالضغط على زر الإضافة',
      ),
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
                  child: Icon(icon, size: 40, color: glass.onGlassMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hint,
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
