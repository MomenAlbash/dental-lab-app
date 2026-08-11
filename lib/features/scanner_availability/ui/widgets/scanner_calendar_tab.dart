import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_day_model.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_calendar/scanner_calendar_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_calendar/scanner_calendar_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Read-only preview of what the rules and exceptions actually produce.
///
/// This is the answer to "did I set it up right?" — the lab edits rules on the
/// other tabs and checks the result here, instead of finding out from a doctor
/// who could not book.
class ScannerCalendarTab extends StatelessWidget {
  const ScannerCalendarTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScannerCalendarCubit, ScannerCalendarState>(
      builder: (context, state) {
        final cubit = context.read<ScannerCalendarCubit>();

        return Column(
          children: [
            _WindowBar(
              from: cubit.from,
              to: cubit.to,
              canGoBack: cubit.canGoBack,
              onPrevious: cubit.previousWindow,
              onNext: cubit.nextWindow,
            ),
            Expanded(
              child: switch (state) {
                ScannerCalendarLoaded(:final days) =>
                  days.isEmpty
                      ? const _Empty()
                      : AdaptiveCollection<ScannerDayModel>(
                          items: days,
                          onRefresh: cubit.getCalendar,
                          cardHeight: 112,
                          itemBuilder: (context, day, _) => _DayCard(day: day),
                        ),
                ScannerCalendarError(:final message) => Center(
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
                  padding: EdgeInsets.only(top: 24),
                  child: GlassListSkeleton(),
                ),
              },
            ),
          ],
        );
      },
    );
  }
}

class _WindowBar extends StatelessWidget {
  const _WindowBar({
    required this.from,
    required this.to,
    required this.canGoBack,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime from;
  final DateTime to;
  final bool canGoBack;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            // Disabled at today: past availability cannot be acted on.
            onPressed: canGoBack ? onPrevious : null,
            tooltip: 'الفترة السابقة',
            icon: const Icon(Icons.chevron_right),
          ),
          Expanded(
            child: Text(
              '${ApiTime.formatDate(from)} → ${ApiTime.formatDate(to)}',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14MediumText.copyWith(
                color: context.glass.onGlass,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: 'الفترة التالية',
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final ScannerDayModel day;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final date = day.date;
    final available = day.availableCount;

    // Open with nothing left is its own state: the rules are fine, the day is
    // simply full, and that reads differently from a closure.
    final (Color accent, String status) = switch ((day.isOpen, available)) {
      (false, _) => (
        glass.error,
        day.closedReason?.trim().isNotEmpty == true
            ? 'مغلق — ${day.closedReason!.trim()}'
            : 'مغلق',
      ),
      (true, 0) => (glass.warning, 'مكتمل — لا مواعيد متاحة'),
      (true, final count) => (glass.success, '$count موعد متاح'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                date == null
                                    ? '—'
                                    : '${WeekDays.labelOf(WeekDays.fromDateTime(date))} ${ApiTime.formatDate(date)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                status,
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (day.slots.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          // The actual slot times, so a wrong slot length or
                          // gap is visible rather than inferred.
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final slot in day.slots)
                                _SlotChip(
                                  label: slot.timeLabel,
                                  isAvailable: slot.isAvailable,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.label, required this.isAvailable});

  final String label;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = isAvailable ? glass.success : glass.onGlassMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(
          color: color,
          // A taken slot is struck through, so it is not colour alone.
          decoration: isAvailable ? null : TextDecoration.lineThrough,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 40,
              color: glass.onGlassMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'لا يوجد أيام في هذه الفترة',
              textAlign: TextAlign.center,
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'أضف موعداً أسبوعياً من تبويب "المواعيد الأسبوعية"',
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
