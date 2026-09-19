import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/scan_storage/data/models/scan_storage_model.dart';
import 'package:dental_lab_app/features/scan_storage/logic/scan_storage/scan_storage_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Confirms that scans have been copied to the laboratory's own NAS.
///
/// **Confirming is what frees the bytes**, so this is the second half of a
/// deliberate two-step flow: the lab's tool downloads each file, writes it to
/// the NAS and verifies it against `contentHash`, and only then is it ticked
/// here. Confirming first and copying afterwards would lose a scan every time
/// the copy failed — which is why nothing on this sheet does the copying.
Future<void> showNasArchiveSheet(
  BuildContext context, {
  required List<PendingNasArchiveModel> pending,
}) {
  final cubit = context.read<ScanStorageCubit>();

  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _NasArchiveSheet(pending: pending),
    ),
  );
}

class _NasArchiveSheet extends StatefulWidget {
  const _NasArchiveSheet({required this.pending});

  final List<PendingNasArchiveModel> pending;

  @override
  State<_NasArchiveSheet> createState() => _NasArchiveSheetState();
}

class _NasArchiveSheetState extends State<_NasArchiveSheet> {
  final _selected = <String>{};

  /// Where the copies were written. One path for the whole batch, because a
  /// lab archives into one share — a per-file path would be a form nobody
  /// fills in honestly.
  final _pathController = TextEditingController();

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  int get _selectedBytes => widget.pending
      .where((scan) => _selected.contains(scan.id))
      .fold(0, (sum, scan) => sum + scan.fileSizeBytes);

  void _confirm(BuildContext context) {
    final path = _pathController.text.trim();

    context.read<ScanStorageCubit>().confirmArchive([
      for (final scan in widget.pending)
        if (_selected.contains(scan.id))
          ConfirmNasArchiveItemModel(
            scanId: scan.id,
            // Recorded so the archive can be followed up on — without it,
            // "archived" is a promise nobody can act on later.
            nasPath: path.isEmpty ? null : '$path/${scan.displayName}',
          ),
    ]);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تأكيد الأرشفة على NAS',
            style: AppTextStyles.font16MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          Text(
            'أكّدوا فقط الملفات اللي صار نسخها فعلياً — التأكيد بيحذفها من '
            'السيرفر.',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.warning,
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selected.isEmpty
                      ? 'لم يُحدَّد شيء'
                      : '${_selected.length} محدَّد '
                            '(${formatBytes(_selectedBytes)})',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  if (_selected.length == widget.pending.length) {
                    _selected.clear();
                  } else {
                    _selected
                      ..clear()
                      ..addAll(widget.pending.map((scan) => scan.id));
                  }
                }),
                child: Text(
                  _selected.length == widget.pending.length
                      ? 'إلغاء التحديد'
                      : 'تحديد الكل',
                ),
              ),
            ],
          ),

          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.35,
            child: ListView.builder(
              itemCount: widget.pending.length,
              itemBuilder: (context, index) {
                final scan = widget.pending[index];

                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selected.contains(scan.id),
                  onChanged: (checked) => setState(() {
                    if (checked ?? false) {
                      _selected.add(scan.id);
                    } else {
                      _selected.remove(scan.id);
                    }
                  }),
                  title: Text(
                    scan.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                  subtitle: Text(
                    [
                      scan.sizeLabel,
                      if (scan.caseNumber != null) 'طلب ${scan.caseNumber}',
                    ].join(' · '),
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
          AppTextFormField(
            controller: _pathController,
            hintText: 'مسار المجلد على الـ NAS (اختياري)',
            validator: (_) => null,
          ),

          const SizedBox(height: AppSpacing.md),
          CustomButtonWidget(
            buttonText: 'تأكيد وتحرير المساحة',
            onPressed: _selected.isEmpty ? null : () => _confirm(context),
          ),
        ],
      ),
    );
  }
}
