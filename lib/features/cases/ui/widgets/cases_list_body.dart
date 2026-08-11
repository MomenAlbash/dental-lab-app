import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_summary_strip.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_state.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_status.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_collection_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The cases list body — reads the [CasesCubit] provided by the page.
class CasesListBody extends StatefulWidget {
  const CasesListBody({super.key, this.scrollController});

  /// Owned by the page, which watches it to collapse the add button.
  final ScrollController? scrollController;

  @override
  State<CasesListBody> createState() => _CasesListBodyState();
}

class _CasesListBodyState extends State<CasesListBody> {
  /// Last loaded cases, kept so a refresh does not blank the list out.
  List<CaseListItemModel>? _lastCases;

  Future<void> _confirmDelete(
    BuildContext context,
    CaseListItemModel caseItem,
  ) async {
    final cubit = context.read<CasesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الحالة',
      message: 'هل أنت متأكد من حذف حالة "${caseItem.patientName ?? ''}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteCase(caseItem.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CasesCubit, CasesState>(
      listener: (context, state) {
        switch (state) {
          case CaseDeleted():
            ShowToast(message: 'تم حذف الحالة', state: toastState.success);
          case CaseDeleteError(:final message):
            ShowToast(message: message, state: toastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! CaseDeleted && current is! CaseDeleteError,
      builder: (context, state) {
        if (state is CasesLoaded) _lastCases = state.cases;

        // A refresh emits CasesLoading. Swapping the list out for the skeleton
        // at that moment unmounts the RefreshIndicator mid-pull, which made
        // pull-to-refresh look like it did nothing. Once we have data, keep
        // showing it and let the indicator run.
        final cases = switch (state) {
          CasesLoaded(:final cases) => cases,
          CasesLoading() => _lastCases,
          _ => null,
        };

        // Cross-fades loading → data → error instead of the content snapping
        // into place.
        return AnimatedSwitcher(
          duration: AppMotion.base,
          switchInCurve: AppMotion.enter,
          child: switch ((state, cases)) {
            (_, final List<CaseListItemModel> loaded) =>
              loaded.isEmpty
                  ? _Empty(key: const ValueKey('cases-empty'))
                  : _CasesList(
                      key: const ValueKey('cases-loaded'),
                      cases: loaded,
                      scrollController: widget.scrollController,
                      onDelete: (c) => _confirmDelete(context, c),
                    ),
            // Only when there is nothing to show: if a refresh fails while data
            // is on screen, the list stays and the toast reports it.
            (CasesError(:final message), null) => Center(
              key: const ValueKey('cases-error'),
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
              key: ValueKey('cases-loading'),
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
  const _Empty({super.key, this.isFiltered = false});

  /// True when the strip hid the rows rather than there being no cases — the
  /// copy has to point at the strip, not at the add button.
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final (IconData icon, String title, String hint) = isFiltered
        ? (
            Icons.filter_alt_off_outlined,
            'لا يوجد حالات بهذه الحالة',
            'اضغط "الكل" لعرض الجميع',
          )
        : (
            Icons.folder_outlined,
            'لا يوجد حالات بعد',
            'أضف أول حالة بالضغط على زر الإضافة',
          );

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

/// Which subset of the loaded cases the list is showing. Mirrors the doctors
/// list's strip, but over the slices that matter for a case.
enum CaseStatusFilter { all, inProgress, rejected }

class _CasesList extends StatefulWidget {
  const _CasesList({
    super.key,
    required this.cases,
    required this.onDelete,
    this.scrollController,
  });

  final List<CaseListItemModel> cases;
  final ValueChanged<CaseListItemModel> onDelete;
  final ScrollController? scrollController;

  @override
  State<_CasesList> createState() => _CasesListState();
}

class _CasesListState extends State<_CasesList> {
  CaseStatusFilter _status = CaseStatusFilter.all;

  List<CaseListItemModel> get _visible => switch (_status) {
    CaseStatusFilter.all => widget.cases,
    CaseStatusFilter.inProgress =>
      widget.cases.where((c) => c.caseStatus == CaseStatus.inProgress).toList(),
    CaseStatusFilter.rejected =>
      widget.cases.where((c) => c.caseStatus == CaseStatus.rejected).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final inProgressCount = widget.cases
        .where((c) => c.caseStatus == CaseStatus.inProgress)
        .length;
    final rejectedCount = widget.cases
        .where((c) => c.caseStatus == CaseStatus.rejected)
        .length;
    final visible = _visible;

    // Case rows carry only the priority's id and name, so its colour has to
    // come from the priorities list. Built once per build rather than looked
    // up per row.
    final prioritiesState = context.watch<CasePrioritiesCubit>().state;
    final variantById = <String, String?>{
      if (prioritiesState is CasePrioritiesLoaded)
        for (final p in prioritiesState.priorities) p.id: p.badgeVariant,
    };

    // The summary strip is identical on every size — a short row of three
    // tiles either way. Only the collection under it changes shape, and
    // AdaptiveCollection owns that.
    return _shell(
      inProgressCount: inProgressCount,
      rejectedCount: rejectedCount,
      collection: visible.isEmpty
          ? const _Empty(isFiltered: true)
          : AdaptiveCollection<CaseListItemModel>(
              items: visible,
              scrollController: widget.scrollController,
              onRefresh: () => context.read<CasesCubit>().getCases(),
              itemBuilder: (context, caseItem, _) => CaseCollectionItem(
                caseItem: caseItem,
                priorityVariant: variantById[caseItem.priorityId],
                onDelete: () => widget.onDelete(caseItem),
              ),
            ),
    );
  }

  /// The parts every shape shares: the status strip, then the collection.
  Widget _shell({
    required int inProgressCount,
    required int rejectedCount,
    required Widget collection,
  }) {
    return Builder(
      builder: (context) {
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
                  child: GlassSummaryStrip<CaseStatusFilter>(
                    tiles: [
                      GlassSummaryTileData(
                        value: CaseStatusFilter.all,
                        label: 'الكل',
                        count: widget.cases.length,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      GlassSummaryTileData(
                        value: CaseStatusFilter.inProgress,
                        label: CaseStatus.inProgress.arabicLabel,
                        count: inProgressCount,
                        color: context.glass.success,
                      ),
                      GlassSummaryTileData(
                        value: CaseStatusFilter.rejected,
                        label: CaseStatus.rejected.arabicLabel,
                        count: rejectedCount,
                        color: context.glass.error,
                      ),
                    ],
                    selected: _status,
                    onSelected: (value) => setState(() => _status = value),
                  ),
                )
                .animate()
                .fadeIn(duration: AppMotion.base)
                .slideY(
                  begin: -0.12,
                  duration: AppMotion.base,
                  curve: AppMotion.enter,
                ),
            Expanded(child: collection),
          ],
        );
      },
    );
  }
}
