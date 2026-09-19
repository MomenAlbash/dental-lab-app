import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/data/repos/laboratories_repo.dart';
import 'package:flutter/material.dart';

/// Picks the laboratory to clone a restoration type into.
///
/// Returns the chosen laboratory's id, or null if cancelled.
Future<String?> showCopyRestorationTypeDialog(
  BuildContext context, {
  required String typeName,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CopyDialog(typeName: typeName),
  );
}

class _CopyDialog extends StatefulWidget {
  const _CopyDialog({required this.typeName});

  final String typeName;

  @override
  State<_CopyDialog> createState() => _CopyDialogState();
}

class _CopyDialogState extends State<_CopyDialog> {
  List<LaboratoryModel>? _laboratories;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<LaboratoriesRepo>().getLaboratories();
    if (!mounted) return;

    final activeId = getIt<LaboratoriesRepo>().activeLaboratoryId;

    setState(() {
      result.fold((failure) => _error = failure.errorMessage, (list) {
        // The source laboratory is left out: copying a type into the branch it
        // already lives in would make a duplicate nobody asked for, and the
        // server refuses it anyway.
        _laboratories = [
          for (final laboratory in list)
            if (laboratory.id != activeId) laboratory,
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final laboratories = _laboratories;

    return AlertDialog(
      title: Text('نسخ التعويض', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              // Said explicitly: the user is about to duplicate pricing and a
              // whole production route, not just a name.
              'سيُنسخ "${widget.typeName}" بأسعاره ومدده ومساره كاملاً إلى الفرع '
              'الذي تختاره.',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: 16),

            if (_error != null)
              Text(
                _error!,
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.error,
                ),
              )
            else if (laboratories == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CustomCircleProgressIndiacatorWidget(),
              )
            else if (laboratories.isEmpty)
              Text(
                'لا يوجد فرع آخر لنسخه إليه',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlassMuted,
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final laboratory in laboratories)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.science_outlined,
                          color: glass.onGlassMuted,
                        ),
                        title: Text(laboratory.name ?? '—'),
                        onTap: () =>
                            Navigator.of(context).pop(laboratory.id),
                      ),
                  ],
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
      ],
    );
  }
}
