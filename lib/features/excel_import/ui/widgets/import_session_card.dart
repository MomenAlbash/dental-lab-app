import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/excel_import/data/models/import_session_model.dart';
import 'package:flutter/material.dart';

/// One import run.
///
/// A run that half worked is the normal case with spreadsheets, so the card
/// reports successes and failures side by side rather than collapsing them
/// into one verdict — "imported 40 of 47" is the fact, and the seven are named
/// by row so the file can be fixed.
class ImportSessionCard extends StatelessWidget {
  const ImportSessionCard({super.key, required this.session});

  final ImportSessionModel session;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final accent = session.didFail
        ? glass.error
        : session.isRunning
        ? glass.info
        : (session.failureCount > 0 ? glass.warning : glass.success);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.displayFileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              Text(
                session.entityLabel,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ],
          ),
          Text(
            ApiTime.displayDateTime(session.startedAt),
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
          if (session.isRunning)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    // Indeterminate until the server has counted the rows —
                    // a full bar over an unknown total would be a lie, and a
                    // zero one reads as stuck.
                    value: session.totalRows > 0 ? session.progress : null,
                    minHeight: 6,
                    backgroundColor: glass.strokeColor,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.totalRows > 0
                      ? '${session.processedRows} من ${session.totalRows} صف'
                      : 'جارٍ القراءة…',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 4,
              children: [
                _Tag(
                  label: 'نجح ${session.successCount}',
                  color: glass.success,
                ),
                if (session.failureCount > 0)
                  _Tag(
                    label: 'فشل ${session.failureCount}',
                    color: glass.warning,
                  ),
                if (session.completedAt != null)
                  _Tag(
                    label: 'انتهى ${ApiTime.displayDateTime(session.completedAt)}',
                    color: glass.onGlassMuted,
                  ),
              ],
            ),

          // The whole run failed, not some of its rows — nothing was
          // imported, which is a different message from "40 of 47".
          if (session.didFail)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                session.failureReason!,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.error,
                ),
              ),
            ),

          if (session.errors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _RowErrors(errors: session.errors),
          ],
        ],
      ),
    );
  }
}

/// The rows that failed, by number.
///
/// Collapsed behind a tile rather than listed inline: a bad file can fail
/// hundreds of rows, and a card that grows to the length of the spreadsheet
/// buries every other run under it.
class _RowErrors extends StatelessWidget {
  const _RowErrors({required this.errors});

  final List<ImportRowErrorModel> errors;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Theme(
      // The default divider makes an expansion tile inside a bordered card
      // look like a second card.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          '${errors.length} صف لم يُستورد',
          style: AppTextStyles.font12RegularHint.copyWith(
            color: glass.warning,
          ),
        ),
        children: [
          for (final error in errors)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The row number is the point: it is how the user finds the
                  // line in their own file.
                  SizedBox(
                    width: 44,
                    child: Text(
                      'صف ${error.rowNumber}',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      error.displayMessage,
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                  ),
                ],
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
