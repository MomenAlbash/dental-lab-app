import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/digital_scan_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// One scan file, ready to upload.
typedef ScanUpload = ({
  String filePath,
  String fileName,
  DigitalScanRole? role,
  String? notes,
  String clientUploadKey,
});

/// Picks a scan file and asks what it is before sending it.
///
/// The role is asked here rather than inferred from the filename: a folder of
/// `scan_001.stl` is unusable at the bench, and the person who just took the
/// scan is the only one who still knows which arch it was.
Future<ScanUpload?> showUploadScanSheet(BuildContext context) {
  return showGlassBottomSheet<ScanUpload>(
    context: context,
    builder: (_) => const _UploadScanSheet(),
  );
}

class _UploadScanSheet extends StatefulWidget {
  const _UploadScanSheet();

  @override
  State<_UploadScanSheet> createState() => _UploadScanSheetState();
}

class _UploadScanSheetState extends State<_UploadScanSheet> {
  final _notesController = TextEditingController();

  String? _filePath;
  String? _fileName;
  DigitalScanRole _role = DigitalScanRole.unspecified;

  /// Minted once, when the sheet opens, and reused for every retry of *this*
  /// file. That is what makes it an idempotency key: a fresh one per attempt
  /// would let a dropped connection store the same scan twice, which matters
  /// when a scan is tens of megabytes on a phone connection.
  final String _clientUploadKey = DateTime.now().microsecondsSinceEpoch
      .toString();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.pickFiles();
    final file = result?.files.single;
    if (file?.path == null) return;

    setState(() {
      _filePath = file!.path;
      _fileName = file.name;
    });
  }

  void _submit() {
    final path = _filePath;
    if (path == null) return;

    final notes = _notesController.text.trim();
    Navigator.of(context).pop((
      filePath: path,
      fileName: _fileName ?? '',
      role: _role,
      notes: notes.isEmpty ? null : notes,
      clientUploadKey: _clientUploadKey,
    ));
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
            'رفع مسح',
            style: AppTextStyles.font16MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.attach_file),
            label: Text(
              _fileName ?? 'اختر ملفاً',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Text(
            'ما هو هذا المسح؟',
            style: AppTextStyles.font14MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final role in DigitalScanRole.values)
                ChoiceChip(
                  label: Text(role.label),
                  selected: _role == role,
                  onSelected: (_) => setState(() => _role = role),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          AppTextFormField(
            controller: _notesController,
            hintText: 'ملاحظات (اختياري)',
            validator: (_) => null,
          ),

          const SizedBox(height: AppSpacing.lg),
          CustomButtonWidget(
            buttonText: 'رفع',
            // Enabled only once a file is actually chosen — a role and notes
            // with nothing to attach them to is not an upload.
            onPressed: _filePath == null ? null : _submit,
          ),
        ],
      ),
    );
  }
}
