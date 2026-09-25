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
