import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:flutter/material.dart';

/// Control's verdict, from [showScannerReviewSheet].
class ScannerReviewChoice {
  const ScannerReviewChoice({required this.approve, this.note});

  final bool approve;
  final String? note;
}

/// Accepts a scan, or sends it back for a redo.
///
/// The note is optional on approval and required on rejection: asking a doctor
/// to rescan a patient without saying what was wrong costs them a second
/// visit, which is not something to discover after the fact.
Future<ScannerReviewChoice?> showScannerReviewSheet(
  BuildContext context, {
  required ScannerSessionModel session,
}) {
  return showGlassBottomSheet<ScannerReviewChoice>(
    context: context,
    builder: (_) => _ReviewSheet(session: session),
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.session});

  final ScannerSessionModel session;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  bool _approve = true;
  final _noteController = TextEditingController();
  String? _noteError;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _confirm() {
    final note = _noteController.text.trim();
    if (!_approve && note.isEmpty) {
      setState(() => _noteError = 'اذكر ما الذي يجب إصلاحه');
      return;
    }

    Navigator.of(context).pop(
      ScannerReviewChoice(approve: _approve, note: note.isEmpty ? null : note),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final session = widget.session;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'مراجعة المسح',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [session.title, session.doctorName]
                  .whereType<String>()
                  .where((s) => s.trim().isNotEmpty)
                  .join(' · '),
              style: AppTextStyles.font13MediumPrimary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),

            // How many times this scan has already come back. A third redo is
            // a conversation with the doctor, not another queue item.
            if (session.redoCount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: glass.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.glass),
                ),
                child: Text(
                  'أُعيد هذا المسح ${session.redoCount} مرة من قبل',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _VerdictCard(
                    icon: Icons.check_circle_outline,
                    label: 'قبول',
                    color: glass.success,
                    isSelected: _approve,
                    onTap: () => setState(() {
                      _approve = true;
                      _noteError = null;
                    }),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _VerdictCard(
                    icon: Icons.replay_outlined,
                    label: 'طلب إعادة',
                    color: glass.error,
                    isSelected: !_approve,
                    onTap: () => setState(() => _approve = false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: _approve
                    ? 'ملاحظة (اختياري)'
                    : 'سبب الإعادة (مطلوب)',
                hintText: _approve ? null : 'ما الذي يجب إصلاحه في المسح؟',
                errorText: _noteError,
              ),
              onChanged: (_) {
                if (_noteError != null) setState(() => _noteError = null);
              },
            ),

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _approve ? glass.success : glass.error,
                    ),
                    onPressed: _confirm,
                    child: Text(_approve ? 'قبول المسح' : 'طلب إعادة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.glass),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? color : glass.strokeColor,
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(AppRadius.glass),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? color : glass.onGlassMuted,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
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
