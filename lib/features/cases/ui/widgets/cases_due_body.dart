import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_state.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_collection_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The cases with a due date, grouped by day — the working stand-in for a
/// real appointment book (see [CasesDueTab]'s doc comment for why).
class CasesDueBody extends StatelessWidget {
  const CasesDueBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CasesCubit, CasesState>(
      builder: (context, state) => switch (state) {
        CasesInitial() || CasesLoading() => const _Skeleton(),
        CasesError(:final message) => _ErrorView(message: message),
        CasesLoaded(:final cases) => switch (_due(cases)) {
          [] => const _EmptyView(),
          final due => _DueList(cases: due),
        },
        _ => const _Skeleton(),
      },
    );
  }

  /// Cases still worth a slot on the schedule: a due date to show, and not
  /// already handed over — a delivered case has nothing left to be "due".
  static List<CaseListItemModel> _due(List<CaseListItemModel> cases) {
    final due = cases
        .where((c) => c.dueDate != null && c.phase != CasePhase.delivered)
        .toList();
    due.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return due;
  }
}

class _DueList extends StatelessWidget {
  const _DueList({required this.cases});

  final List<CaseListItemModel> cases;

  /// Splits the (already date-sorted) list into day buckets, preserving
  /// order.
  List<(DateTime, List<CaseListItemModel>)> get _byDay {
    final groups = <(DateTime, List<CaseListItemModel>)>[];

    for (final caseItem in cases) {
      final at = DateTime.tryParse(caseItem.dueDate!);
      if (at == null) continue;
      final day = DateTime(at.year, at.month, at.day);

      if (groups.isNotEmpty && groups.last.$1 == day) {
        groups.last.$2.add(caseItem);
      } else {
        groups.add((day, [caseItem]));
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _byDay;
    final prioritiesState = context.watch<CasePrioritiesCubit>().state;
    final variantById = <String, String?>{
      if (prioritiesState is CasePrioritiesLoaded)
        for (final p in prioritiesState.priorities) p.id: p.badgeVariant,
    };

    return RefreshIndicator(
      onRefresh: () => context.read<CasesCubit>().getCases(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screen),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final (day, dayCases) = groups[index];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (index > 0) const SizedBox(height: AppSpacing.lg),
              _DayHeader(day: day, count: dayCases.length),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < dayCases.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _CaseRow(
                  caseItem: dayCases[i],
                  priorityVariant: variantById[dayCases[i].priorityId],
                  index: i,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CaseRow extends StatelessWidget {
  const _CaseRow({
    required this.caseItem,
    required this.priorityVariant,
    required this.index,
  });

  final CaseListItemModel caseItem;
  final String? priorityVariant;
  final int index;

  @override
  Widget build(BuildContext context) {
    return CaseCollectionItem(
          caseItem: caseItem,
          priorityVariant: priorityVariant,
          // This tab only ever reads the schedule — deleting a case belongs
          // to the cases list, not a glance-level due list.
          onDelete: null,
        )
        .animate(delay: AppMotion.staggerFor(index))
        .fadeIn(duration: AppMotion.base)
        .slideY(begin: 0.08, duration: AppMotion.base, curve: AppMotion.enter);
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.count});

  final DateTime day;
  final int count;

  static const _weekdays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  /// "اليوم" / "غداً" where they apply, otherwise the weekday plus a numeric
  /// date.
  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = day.difference(today).inDays;

    final date =
        '${day.day.toString().padLeft(2, '0')}/'
        '${day.month.toString().padLeft(2, '0')}/${day.year}';

    return switch (difference) {
      0 => 'اليوم · $date',
      1 => 'غداً · $date',
      -1 => 'أمس · $date',
      _ => '${_weekdays[day.weekday - 1]} · $date',
    };
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // A day already past and still on the schedule is a case running behind
    // — the warning tint says so before the reader has to check the date.
    final isOverdue = day.isBefore(today);
    final accent = isOverdue
        ? glass.warning
        : Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            _label(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font16MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.font12RegularHint.copyWith(color: accent),
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: const [
        GlassSkeletonBox(width: 160, height: 20),
        SizedBox(height: AppSpacing.md),
        GlassSkeletonBox(height: 96),
        SizedBox(height: AppSpacing.sm),
        GlassSkeletonBox(height: 96),
        SizedBox(height: AppSpacing.lg),
        GlassSkeletonBox(width: 160, height: 20),
        SizedBox(height: AppSpacing.md),
        GlassSkeletonBox(height: 96),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_available_outlined,
                  size: 24,
                  color: accent.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'لا توجد مواعيد تسليم قادمة',
              textAlign: TextAlign.center,
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'تُحدَّد المواعيد من تاريخ التسليم المتوقَّع لكل حالة.',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: glass.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.read<CasesCubit>().getCases(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
