import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:flutter/material.dart';

/// What the case's current lifecycle checkpoint asks of the user, with the
/// note that goes on the record.
///
/// The lifecycle (`CasePhase`) is fixed and is **not** moved by picking a
/// stage — each step past it is its own action, and which action is offered
/// depends entirely on where the case stands. A case in `New` shows "تسجيل
/// الاستلام" and nothing else, which is also why its workflow stages refuse to
/// move until that is done.
class CasePhaseActionCard extends StatefulWidget {
  const CasePhaseActionCard({
    super.key,
    required this.phase,
    required this.isBusy,
    required this.onReceiveMaterial,
    required this.onPassQualityCheck,
    required this.onApproveTrying,
    required this.onUndoReceiveMaterial,
    required this.onRejectTrying,
  });

  final CasePhase? phase;
  final bool isBusy;

  final ValueChanged<String?> onReceiveMaterial;
  final ValueChanged<String?> onPassQualityCheck;
  final ValueChanged<String?> onApproveTrying;

  /// Walks back an arrival recorded against the wrong case. Offered only where
  /// it means anything — once the case has left `Received`, its stages have
  /// moved and the server refuses.
  final VoidCallback onUndoReceiveMaterial;

  /// The other half of trying: the doctor refused the fit, and the flagged
  /// pieces go back. Sits beside "قبول التجربة" rather than being buried in
  /// each piece's move sheet, because it is one decision about the case.
  final VoidCallback onRejectTrying;

  @override
  State<CasePhaseActionCard> createState() => _CasePhaseActionCardState();
}

class _CasePhaseActionCardState extends State<CasePhaseActionCard> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String? get _note {
    final note = _noteController.text.trim();
    return note.isEmpty ? null : note;
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    // Only the phases that have an action of their own. `InProduction` is the
    // case's blind spot — the work is on the stages and the units then, and
    // offering a button here would imply a way past production that does not
    // exist. `Delivered` is the end.
    final (
      String label,
      VoidCallback? action,
      String hint,
    ) = switch (widget.phase) {
      CasePhase.newCase || CasePhase.received => (
        'تسجيل الاستلام',
        () => widget.onReceiveMaterial(_note),
        'سجّل استلام العمل لتبدأ الحالة مسارها',
      ),
      CasePhase.qualityCheck => (
        'اجتياز فحص الجودة',
        () => widget.onPassQualityCheck(_note),
        'أكّد أن العمل اجتاز الفحص',
      ),
      CasePhase.ready => (
        'قبول التجربة',
        () => widget.onApproveTrying(_note),
        'إن رفض الطبيب التجربة، سجّل الرفض وحدّد المرحلة التي يعود إليها كل تعويض',
      ),
      _ => ('', null, ''),
    };

    if (action == null) return const SizedBox.shrink();

    // The second, opposite action of this checkpoint — the one that undoes it
    // or refuses it. Only two phases have one.
    final (String? secondLabel, VoidCallback? secondAction) =
        switch (widget.phase) {
          CasePhase.received => (
            'التراجع عن الاستلام',
            widget.onUndoReceiveMaterial,
          ),
          CasePhase.ready => ('رفض التجربة', widget.onRejectTrying),
          _ => (null, null),
        };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: glass.accentSurface,
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'الحالة الآن: ${widget.phase?.label ?? '—'}',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextFormField(
            controller: _noteController,
            hintText: 'ملاحظة (اختيارية)',
            validator: (_) => null,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: widget.isBusy ? null : action,
            child: Text(label),
          ),
          if (secondLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: OutlinedButton(
                onPressed: widget.isBusy ? null : secondAction,
                child: Text(secondLabel),
              ),
            ),
        ],
      ),
    );
  }
}
