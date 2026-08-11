import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Generic attachments list: a header with an "add" action plus one card per
/// file, each colour-coded by extension. Actions are disabled while [isBusy].
///
/// Every feature with file attachments (doctors, patients, employees, ...)
/// used to keep its own byte-for-byte copy of this section with only the
/// model type swapped. It is generic over [T] — the entity-specific
/// attachment model — so one widget serves them all: pass in how to read an
/// id and a file name and it does the rest.
class GlassAttachmentsSection<T> extends StatelessWidget {
  const GlassAttachmentsSection({
    super.key,
    required this.files,
    required this.isBusy,
    required this.onAddFile,
    required this.onDeleteFile,
    required this.onOpenFile,
    required this.idOf,
    required this.fileNameOf,
    this.title = 'المرفقات',
  });

  final List<T> files;
  final bool isBusy;
  final VoidCallback onAddFile;
  final ValueChanged<String> onDeleteFile;
  final ValueChanged<T> onOpenFile;
  final String Function(T file) idOf;
  final String? Function(T file) fileNameOf;
  final String title;

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
                title,
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
          GlassDottedUploadArea(onTap: isBusy ? null : onAddFile)
        else
          for (var i = 0; i < files.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child:
                  _AttachmentCard(
                        fileName: fileNameOf(files[i]),
                        isBusy: isBusy,
                        onOpen: () => onOpenFile(files[i]),
                        onDelete: () => onDeleteFile(idOf(files[i])),
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

/// A dashed-looking drop zone shown when there are no files yet. Flutter has
/// no dashed border primitive, so the affordance comes from a translucent
/// fill and a soft inset edge instead of a custom painter — same read, far
/// less code to maintain.
class GlassDottedUploadArea extends StatelessWidget {
  const GlassDottedUploadArea({
    super.key,
    this.onTap,
    this.title = 'لا يوجد مرفقات',
    this.subtitle = 'اضغط لإضافة ملف',
  });

  final VoidCallback? onTap;
  final String title;
  final String subtitle;

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
          child: Column(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 32,
                color: glass.onGlassMuted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.font14MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.fileName,
    required this.isBusy,
    required this.onOpen,
    required this.onDelete,
  });

  final String? fileName;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  String get _name => fileName?.isNotEmpty == true ? fileName! : 'ملف';

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
                icon: Icon(Icons.delete_outline, color: glass.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
