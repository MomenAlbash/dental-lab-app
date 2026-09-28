import 'package:dental_lab_app/core/helper/laboratory_scope.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// Asks which laboratory a new record belongs to, when several are being
/// viewed together. Returns the chosen id, or null when cancelled.
///
/// Shown for every create — a case, a doctor, a patient, anything — because
/// viewing two laboratories together is only a view: each record still lives
/// in exactly one of them.
Future<String?> showLaboratoryPickerDialog(
  BuildContext context,
  List<ScopedLaboratory> options,
) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      final glass = context.glass;

      return AlertDialog(
        title: const Text('إلى أي مخبر تُضاف؟'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'أنت تعرض أكثر من مخبر، والسجل الجديد يتبع مخبراً واحداً.',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              const SizedBox(height: 8),
              for (final laboratory in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.science_outlined),
                  title: Text(
                    laboratory.name.isEmpty ? '—' : laboratory.name,
                  ),
                  onTap: () => Navigator.of(context).pop(laboratory.id),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      );
    },
  );
}

/// Opens a create form in one laboratory — asked for up front when several
/// are in view, so the whole form works in it: its pickers only offer that
/// laboratory's doctors, clinics and patients, and saving needs no second
/// question. Returns null without opening anything when the user cancels.
///
/// With one laboratory, or inside a form that already pinned one (adding a
/// doctor from the case form), it simply opens.
Future<T?> openInLaboratory<T>(
  BuildContext context,
  Future<T?> Function() open,
) async {
  if (LaboratoryScope.pinned != null || !LaboratoryScope.isMulti) {
    return open();
  }

  final laboratoryId = await showLaboratoryPickerDialog(
    context,
    LaboratoryScope.laboratories,
  );
  if (laboratoryId == null) return null;

  return LaboratoryScope.runPinned(laboratoryId, open);
}
