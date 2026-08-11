import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_attachment_file_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Attachments for a doctor: a header with an "add" action plus one card per
/// file. Actions are disabled while [isBusy].
///
/// Each row leads with a colour-coded badge derived from the file extension so
/// documents are scannable by type rather than by reading every file name.
class DoctorAttachmentsSection extends StatelessWidget {
  const DoctorAttachmentsSection({
    super.key,
    required this.files,
    required this.isBusy,
    required this.onAddFile,
    required this.onDeleteFile,
    required this.onOpenFile,
  });

  final List<DoctorAttachmentFileModel> files;
  final bool isBusy;
  final VoidCallback onAddFile;
  final ValueChanged<String> onDeleteFile;
  final ValueChanged<DoctorAttachmentFileModel> onOpenFile;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Flexible so a large system text scale ellipsises the heading
            // instead of pushing the add button off the row.
            Flexible(
              child: Text(
                'المرفقات',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font16MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
            ),
            if (files.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              _CountBadge(count: files.length),
            ],
            const Spacer(),
            TextButton.icon(
              onPressed: isBusy ? null : onAddFile,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'إضافة',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (files.isEmpty)
          _EmptyAttachments(onAddFile: isBusy ? null : onAddFile)
        else
          for (var i = 0; i < files.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child:
                  _AttachmentCard(
                        file: files[i],
                        isBusy: isBusy,
                        onOpen: () => onOpenFile(files[i]),
                        onDelete: () => onDeleteFile(files[i].id),
                      )
                      .animate(delay: AppMotion.staggerFor(i))
                      .fadeIn(duration: AppMotion.base)
                      .slideY(
                        begin: 0.1,
                        duration: AppMotion.base,
                        curve: AppMotion.enter,
                      ),
            ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.font12RegularHint.copyWith(color: accent),
      ),
    );
  }
}

class _EmptyAttachments extends StatelessWidget {
  const _EmptyAttachments({required this.onAddFile});

  final VoidCallback? onAddFile;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return DottedUploadArea(
      onTap: onAddFile,
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 32,
            color: glass.onGlassMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'لا يوجد مرفقات',
            style: AppTextStyles.font14MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'اضغط لإضافة ملف',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A dashed-looking drop zone. Flutter has no dashed border primitive, so the
/// affordance comes from a translucent fill and a soft inset edge instead of a
/// custom painter — same read, far less code to maintain.
class DottedUploadArea extends StatelessWidget {
  const DottedUploadArea({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          decoration: BoxDecoration(
            color: glass.onGlassMuted.withValues(alpha: 0.05),
            borderRadius: radius,
            border: Border.all(
              color: glass.onGlassMuted.withValues(alpha: 0.28),
              width: 1.4,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.file,
    required this.isBusy,
    required this.onOpen,
    required this.onDelete,
  });

  final DoctorAttachmentFileModel file;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  String get _name =>
      file.fileName?.isNotEmpty == true ? file.fileName! : 'ملف';

  String get _extension {
    final dot = _name.lastIndexOf('.');
    if (dot == -1 || dot == _name.length - 1) return '';
    return _name.substring(dot + 1).toUpperCase();
  }

  /// Colour and glyph per family, so a PDF never looks like an image.
  (IconData, Color) _badge(BuildContext context) => switch (_extension) {
    'PDF' => (Icons.picture_as_pdf_outlined, const Color(0xFFDC2626)),
    'DOC' || 'DOCX' => (Icons.description_outlined, const Color(0xFF2F80ED)),
    'XLS' ||
    'XLSX' ||
    'CSV' => (Icons.table_chart_outlined, const Color(0xFF16A34A)),
    'PNG' ||
    'JPG' ||
    'JPEG' ||
    'WEBP' ||
    'GIF' => (Icons.image_outlined, const Color(0xFF8B5CF6)),
    'ZIP' ||
    'RAR' ||
    '7Z' => (Icons.folder_zip_outlined, const Color(0xFFEAB308)),
    _ => (
      Icons.insert_drive_file_outlined,
      Theme.of(context).colorScheme.primary,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final (icon, color) = _badge(context);
    final radius = BorderRadius.circular(AppRadius.glass);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            borderRadius: radius,
            border: Border.all(color: glass.strokeColor),
            boxShadow: glass.shadows,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.font14MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                    if (_extension.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _extension,
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 17, color: glass.onGlassMuted),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'حذف',
                onPressed: isBusy ? null : onDelete,
                icon: Icon(Icons.delete_outline, color: context.glass.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
