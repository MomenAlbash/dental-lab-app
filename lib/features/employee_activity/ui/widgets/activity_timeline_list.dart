import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/features/employee_activity/data/models/employee_activity_model.dart';
import 'package:flutter/material.dart';

/// The individual recorded events, newest first, paged.
class ActivityTimelineList extends StatefulWidget {
  const ActivityTimelineList({
    super.key,
    required this.timeline,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  /// Null until the tab is opened — the events are the heaviest of the three
  /// reads, so they are not fetched with the summary.
  final ActivityTimelineModel? timeline;

  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  State<ActivityTimelineList> createState() => _ActivityTimelineListState();
}

class _ActivityTimelineListState extends State<ActivityTimelineList> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Fetches the next page before the user hits the bottom, so a long list
  /// does not stutter at every page boundary.
  void _onScroll() {
    if (!_controller.hasClients) return;

    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final timeline = widget.timeline;

    if (timeline == null) {
      return const Center(child: CustomCircleProgressIndiacatorWidget());
    }

    if (timeline.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'لا توجد أحداث في هذه الفترة',
            textAlign: TextAlign.center,
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.all(AppSpacing.lg),
      // One extra row for the footer: either the spinner for the next page or
      // the total, so the end of the list says which it is.
      itemCount: timeline.items.length + 1,
      itemBuilder: (context, index) {
        if (index == timeline.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: widget.isLoadingMore
                  ? const CustomCircleProgressIndiacatorWidget()
                  : Text(
                      '${timeline.items.length} من ${timeline.totalCount}',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
            ),
          );
        }

        return _EventRow(item: timeline.items[index]);
      },
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.item});

  final ActivityTimelineItemModel item;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    // Rework, a rejection or a repeat pass — the rows worth a second look, so
    // they are outlined rather than left to be found by reading every line.
    final accent = item.isRejected
        ? glass.error
        : (item.needsAttention ? glass.warning : glass.strokeColor);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(
          color: accent,
          width: item.needsAttention ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.displayUser,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              Text(
                ApiTime.displayDateTime(item.at),
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),
          Text(
            item.moveLabel,
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlass,
            ),
          ),

          Text(
            [
              item.kind?.label ?? '—',
              if (item.caseNumber != null) 'طلب ${item.caseNumber}',
              if (item.restorationLabel?.isNotEmpty ?? false)
                item.restorationLabel!,
              if (item.doctorName?.isNotEmpty ?? false) item.doctorName!,
              if (item.patientName?.isNotEmpty ?? false) item.patientName!,
            ].join(' · '),
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),

          if (item.needsAttention) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 4,
              children: [
                if (item.isRejected)
                  _Tag(label: 'مرفوضة', color: glass.error),
                if (item.isReturn && !item.isRejected)
                  _Tag(label: 'مرتجعة', color: glass.warning),
                // Above one, the work is being redone — which is what turns a
                // row from a record into a question.
                if (item.attempt > 1)
                  _Tag(
                    label: 'المحاولة ${item.attempt}',
                    color: glass.warning,
                  ),
              ],
            ),
          ],

          // A rejection carries a reason somebody has to answer for, so it is
          // shown in full rather than being left to the case screen.
          if (item.reason?.trim().isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.reason!,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.error,
                ),
              ),
            ),
          if (item.note?.trim().isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                item.note!,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}
