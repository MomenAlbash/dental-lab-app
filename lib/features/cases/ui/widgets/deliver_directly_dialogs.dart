import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/cases/data/models/case_flow_model.dart';
import 'package:dental_lab_app/features/cases/data/models/deliver_directly_models.dart';
import 'package:flutter/material.dart';

/// What the user confirmed. [collectionMethod] is only asked for a single
/// case — the bulk call takes none.
typedef DeliverDirectlyChoice = ({
  String? note,
  CollectionMethod collectionMethod,
});

/// Confirms "تم التسليم": every remaining stage is completed at once, which
/// is not something to do by a mis-tap. Null means cancelled.
Future<DeliverDirectlyChoice?> showDeliverDirectlyDialog(
  BuildContext context, {
  required int caseCount,
  bool askCollectionMethod = false,
}) {
  return showDialog<DeliverDirectlyChoice>(
    context: context,
    builder: (_) => _DeliverDirectlyDialog(
      caseCount: caseCount,
      askCollectionMethod: askCollectionMethod,
    ),
  );
}

class _DeliverDirectlyDialog extends StatefulWidget {
  const _DeliverDirectlyDialog({
    required this.caseCount,
    required this.askCollectionMethod,
  });

  final int caseCount;
  final bool askCollectionMethod;

  @override
  State<_DeliverDirectlyDialog> createState() => _DeliverDirectlyDialogState();
}

class _DeliverDirectlyDialogState extends State<_DeliverDirectlyDialog> {
  final _noteController = TextEditingController();
  CollectionMethod _collectionMethod = CollectionMethod.none;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final count = widget.caseCount;

    return AlertDialog(
      title: const Text('تم التسليم'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              count == 1
                  ? 'ستُكمَل كل المراحل المتبقية لهذه الحالة وتُسجَّل مسلّمة.'
                  : 'ستُكمَل كل المراحل المتبقية لـ $count حالة وتُسجَّل مسلّمة.',
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // The history keeps a marker, so this is not a silent
              // shortcut — say so, it is why the action is acceptable.
              'يظهر في سجل كل حالة أن المراحل أُكملت بالتسليم المباشر.',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
            if (widget.askCollectionMethod) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<CollectionMethod>(
                initialValue: _collectionMethod,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'طريقة الاستلام',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final method in CollectionMethod.values)
                    DropdownMenuItem(
                      value: method,
                      child: Text(method.label.isEmpty ? 'بدون' : method.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _collectionMethod = value);
                  }
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'ملاحظة (اختيارية)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () {
            final note = _noteController.text.trim();
            Navigator.of(context).pop((
              note: note.isEmpty ? null : note,
              collectionMethod: _collectionMethod,
            ));
          },
          child: const Text('تسليم'),
        ),
      ],
    );
  }
}

/// The bulk call's per-case outcome: how many made it, and why the others
/// stopped where they did.
Future<void> showDeliverDirectlyResultsSheet(
  BuildContext context, {
  required List<DeliverDirectlyResultModel> results,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => _ResultsSheet(results: results),
  );
}

class _ResultsSheet extends StatelessWidget {
  const _ResultsSheet({required this.results});

  final List<DeliverDirectlyResultModel> results;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final delivered = results.where((r) => r.delivered).length;
    final stopped = results.where((r) => !r.delivered).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'نتيجة التسليم',
            style: AppTextStyles.font18MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CountRow(
            icon: Icons.check_circle_outline,
            color: glass.success,
            text: 'سُلّمت $delivered من ${results.length}',
          ),
          if (stopped.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _CountRow(
              icon: Icons.error_outline,
              color: glass.error,
              text:
                  'توقّفت ${stopped.length} — بقيت كل منها عند آخر مرحلة نجحت',
            ),
            const SizedBox(height: AppSpacing.md),
            for (final row in stopped)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  '${row.caseNumber ?? 'حالة غير موجودة'}: '
                  '${row.error ?? 'لم تُسلَّم'}',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.font14MediumText.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
