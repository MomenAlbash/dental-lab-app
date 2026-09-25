import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
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
import 'package:dental_lab_app/features/cases/data/models/case_counts_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/deliver_directly_models.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_collection_item.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/deliver_directly_dialogs.dart';
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
  /// The last loaded state, kept so a refresh does not blank the list out —
  /// and so the tab bar keeps its counts and its selection while the rows
  /// behind it are being refetched.
  CasesLoaded? _lastLoaded;

  /// Cases picked for a bulk action. Empty means not selecting — a long
  /// press on a row starts it. Local UI state: nothing is sent until the
  /// user confirms.
  final Set<String> _selected = {};

  void _toggleSelected(CaseListItemModel caseItem) {
    if (caseItem.phase == CasePhase.delivered) {
      showToast(message: 'هذه الحالة مسلّمة أصلاً', state: ToastState.error);
      return;
    }
    const max = DeliverDirectlyResultModel.maxCasesPerRequest;
    if (!_selected.contains(caseItem.id) && _selected.length >= max) {
      // The server refuses a bigger batch outright; stop here instead.
      showToast(
        message: 'الحد الأقصى $max حالة في المرة الواحدة',
        state: ToastState.error,
      );
      return;
    }
    setState(() {
      if (!_selected.remove(caseItem.id)) _selected.add(caseItem.id);
    });
  }

  Future<void> _deliverSelected(BuildContext context) async {
    final cubit = context.read<CasesCubit>();

    final choice = await showDeliverDirectlyDialog(
      context,
      caseCount: _selected.length,
    );
    if (choice == null) return;

    await cubit.deliverDirectly(_selected.toList(), note: choice.note);
  }

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
            showToast(message: 'تم حذف الحالة', state: ToastState.success);
          case CaseDeleteError(:final message):
            showToast(message: message, state: ToastState.error);
          case CasesDeliveredDirectly(:final results):
            setState(_selected.clear);
            showDeliverDirectlyResultsSheet(context, results: results);
          // The selection survives a failed call, so it can be retried.
          case CasesDeliverDirectlyError(:final message):
            showToast(message: message, state: ToastState.error);
          // A new page of rows (a tab, a filter) drops picks no longer shown:
          // acting on cases the user cannot see is not a choice they made.
          case CasesLoaded(:final cases) when _selected.isNotEmpty:
            final shown = {for (final c in cases) c.id};
            setState(() => _selected.retainWhere(shown.contains));
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! CaseDeleted &&
          current is! CaseDeleteError &&
          current is! CasesDeliveredDirectly &&
          current is! CasesDeliverDirectlyError,
      builder: (context, state) {
        if (state is CasesLoaded) _lastLoaded = state;
        // A "my tasks" queue with nothing assigned has no rows to keep, and
        // holding the previous list would answer a question nobody asked.
        if (state is CasesNoAssignments) _lastLoaded = null;

        // A refresh emits CasesLoading. Swapping the list out for the skeleton
        // at that moment unmounts the RefreshIndicator mid-pull, which made
        // pull-to-refresh look like it did nothing. Once we have data, keep
        // showing it and let the indicator run.
        final loaded = switch (state) {
          final CasesLoaded loaded => loaded,
          CasesLoading() => _lastLoaded,
          _ => null,
        };

        final canSelect = getIt<SessionCubit>().state.canEdit(
          PermissionName.cases,
        );

        // Cross-fades loading → data → error instead of the content snapping
        // into place.
        final content = AnimatedSwitcher(
          duration: AppMotion.base,
          switchInCurve: AppMotion.enter,
          child: switch ((state, loaded)) {
            (CasesNoAssignments(), _) => const _Empty(
              key: ValueKey('cases-no-assignments'),
              isUnassigned: true,
            ),
            (_, final CasesLoaded shown) => _CasesList(
              key: const ValueKey('cases-loaded'),
              state: shown,
              scrollController: widget.scrollController,
              selectedIds: _selected.isEmpty ? null : _selected,
              onToggleSelected: canSelect ? _toggleSelected : null,
              // Hidden outright without the permission rather than shown and
              // refused: an action the server will reject is not an action,
              // and the refusal arrives with no explanation the user can act
              // on.
              onDelete:
                  getIt<SessionCubit>().state.canEdit(PermissionName.cases)
                  ? (c) => _confirmDelete(context, c)
                  : null,
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

        if (_selected.isEmpty) return content;
        return Column(
          children: [
            Expanded(child: content),
            _SelectionBar(
              count: _selected.length,
              isBusy: state is CasesLoading,
              onClear: () => setState(_selected.clear),
              onDeliver: () => _deliverSelected(context),
            ),
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({super.key, this.isFiltered = false, this.isUnassigned = false});

  /// True when a tab or the date segment hid the rows rather than there being
  /// no cases — the copy has to point at the strip, not at the add button.
  final bool isFiltered;

  /// True in the "my tasks" queue when this login is assigned no stages at
  /// all. A different sentence from "no cases": one is about the laboratory,
  /// the other about who you are in it.
  final bool isUnassigned;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final (IconData icon, String title, String hint) = isUnassigned
        ? (
            Icons.assignment_ind_outlined,
            'لا توجد مراحل مسندة إليك',
            'اطلب من المسؤول إسنادك إلى مرحلة أو قسم لتظهر مهامك هنا',
          )
        : isFiltered
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

/// The rows, under the lifecycle tabs and the date segment.
///
/// **Both controls re-query the server.** They used to slice the page already
/// in memory, which meant the counts described 200 rows rather than the
/// laboratory, and "متأخرة: 3" was true only of what had been fetched. The tab
/// counts now come from `phase-counts` and the date counts from `sla-counts`,
/// both taken under the same filters the list itself is showing.
class _CasesList extends StatelessWidget {
  const _CasesList({
    super.key,
    required this.state,
    required this.onDelete,
    this.scrollController,
    this.selectedIds,
    this.onToggleSelected,
  });

  final CasesLoaded state;

  /// Null when the user may not delete — the row then carries no delete
  /// button at all.
  final ValueChanged<CaseListItemModel>? onDelete;
  final ScrollController? scrollController;

  /// Null outside selection mode.
  final Set<String>? selectedIds;

  /// Null when the user may not act on cases in bulk.
  final ValueChanged<CaseListItemModel>? onToggleSelected;

  @override
  Widget build(BuildContext context) {
    final cases = state.cases;

    // Case rows carry only the priority's id and name, so its colour has to
    // come from the priorities list. Built once per build rather than looked
    // up per row.
    final prioritiesState = context.watch<CasePrioritiesCubit>().state;
    final variantById = <String, String?>{
      if (prioritiesState is CasePrioritiesLoaded)
        for (final p in prioritiesState.priorities) p.id: p.badgeVariant,
    };

    // The strip and the segment are identical on every size — short rows
    // either way. Only the collection under them changes shape, and
    // AdaptiveCollection owns that.
    return _shell(
      collection: cases.isEmpty
          ? _Empty(
              isFiltered:
                  state.filters.phaseTab != CasePhaseTab.all ||
                  state.filters.sla != CaseSlaFilter.none,
            )
          : AdaptiveCollection<CaseListItemModel>(
              items: cases,
              scrollController: scrollController,
              onRefresh: () => context.read<CasesCubit>().getCases(),
              itemBuilder: (context, caseItem, _) => CaseCollectionItem(
                caseItem: caseItem,
                priorityVariant: variantById[caseItem.priorityId],
                onDelete: onDelete == null ? null : () => onDelete!(caseItem),
                isSelected: selectedIds?.contains(caseItem.id),
                onToggleSelected: onToggleSelected == null
                    ? null
                    : () => onToggleSelected!(caseItem),
              ),
            ),
    );
  }

  /// The parts every shape shares: the tab strip, the date segment, then the
  /// collection.
  Widget _shell({required Widget collection}) {
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
                  child: GlassSummaryStrip<CasePhaseTab>(
                    tiles: [
                      for (final tab in CasePhaseTab.values)
                        GlassSummaryTileData(
                          value: tab,
                          label: tab.shortLabel,
                          // Shown at zero, never hidden: "nothing waiting to
                          // be received" is an answer, and a tab that vanishes
                          // reads as broken.
                          count: state.phaseCounts.countOf(tab),
                          color: switch (tab) {
                            CasePhaseTab.all => Theme.of(
                              context,
                            ).colorScheme.primary,
                            CasePhaseTab.newCases => context.glass.warning,
                            CasePhaseTab.inProduction => context.glass.info,
                            CasePhaseTab.ready => context.glass.success,
                            CasePhaseTab.delivered =>
                              context.glass.onGlassMuted,
                          },
                        ),
                    ],
                    selected: state.filters.phaseTab,
                    onSelected: (tab) =>
                        context.read<CasesCubit>().setPhaseTab(tab),
                  ),
                )
                .animate()
                .fadeIn(duration: AppMotion.base)
                .slideY(
                  begin: -0.12,
                  duration: AppMotion.base,
                  curve: AppMotion.enter,
                ),
            _SlaSegment(
              counts: state.slaCounts,
              selected: state.filters.sla,
              horizontal: horizontal,
            ),
            Expanded(child: collection),
          ],
        );
      },
    );
  }
}

/// The three date badges: late, due today, never promised a date.
///
/// Chips rather than a fourth row of tiles: this is a question you ask *on
/// top* of a tab ("of the cases in production, which are late"), and unlike
/// the tabs it can be off entirely — tapping the selected chip clears it.
///
/// The three exclude one another server-side, so only one can be on at a time.
class _SlaSegment extends StatelessWidget {
  const _SlaSegment({
    required this.counts,
    required this.selected,
    required this.horizontal,
  });

  final CaseSlaCountsModel counts;
  final CaseSlaFilter selected;
  final double horizontal;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    // A scrolling Row rather than a horizontal ListView: the collection below
    // is the screen's list, and a second one here would make "is this shape a
    // list or a grid" ambiguous to anything reading the tree.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          for (final filter in const [
            CaseSlaFilter.late$,
            CaseSlaFilter.dueToday,
            CaseSlaFilter.noExpectedCompletion,
          ])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: FilterChip(
                selected: selected == filter,
                showCheckmark: false,
                // Kept at zero rather than hidden, same rule as the tabs: an
                // empty "متأخرة" is the best news on this screen, and it can
                // only be read if the chip is there to say it.
                label: Text('${filter.label} (${counts.countOf(filter)})'),
                labelStyle: AppTextStyles.font12RegularHint.copyWith(
                  color: selected == filter
                      ? Theme.of(context).colorScheme.primary
                      : glass.onGlassMuted,
                ),
                onSelected: (_) =>
                    context.read<CasesCubit>().toggleSlaFilter(filter),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pinned under the list while cases are picked: how many, and what to do
/// with them.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.isBusy,
    required this.onClear,
    required this.onDeliver,
  });

  final int count;
  final bool isBusy;
  final VoidCallback onClear;
  final VoidCallback onDeliver;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: glass.surfaceGradient,
          border: Border(top: BorderSide(color: glass.strokeColor)),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'إلغاء التحديد',
              onPressed: isBusy ? null : onClear,
              icon: const Icon(Icons.close),
            ),
            Expanded(
              child: Text(
                '$count محددة',
                style: AppTextStyles.font14MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
            ),
            FilledButton.icon(
              // The theme's buttons are full-width; in a row that is an
              // infinite width, so this one sizes to its label.
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: isBusy ? null : onDeliver,
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('تم التسليم'),
            ),
          ],
        ),
      ),
    );
  }
}
