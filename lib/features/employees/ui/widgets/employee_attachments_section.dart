import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_attachment_file_model.dart';
import 'package:flutter/material.dart';

/// Attachments list for an employee: a header with an "add" action plus each
/// file row with open and delete actions. Actions are disabled while [isBusy].
class EmployeeAttachmentsSection extends StatelessWidget {
  const EmployeeAttachmentsSection({
    super.key,
    required this.files,
    required this.isBusy,
    required this.onAddFile,
    required this.onDeleteFile,
    required this.onOpenFile,
  });

  final List<EmployeeAttachmentFileModel> files;
  final bool isBusy;
  final VoidCallback onAddFile;
  final ValueChanged<String> onDeleteFile;
  final ValueChanged<EmployeeAttachmentFileModel> onOpenFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'الملفات المرفقة',
                style: AppTextStyles.font16MediumText,
              ),
            ),
            TextButton.icon(
              onPressed: isBusy ? null : onAddFile,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('إضافة ملف'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (files.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'لا يوجد ملفات مرفقة',
              style: AppTextStyles.font14RegularSecondary,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColorsManger.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColorsManger.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < files.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColorsManger.divider),
                  _AttachmentRow(
                    file: files[i],
                    isBusy: isBusy,
                    onOpen: () => onOpenFile(files[i]),
                    onDelete: () => onDeleteFile(files[i].id),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.file,
    required this.isBusy,
    required this.onOpen,
    required this.onDelete,
  });

  final EmployeeAttachmentFileModel file;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              color: AppColorsManger.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file.fileName?.isNotEmpty == true ? file.fileName! : 'ملف',
                style: AppTextStyles.font14MediumText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.open_in_new,
              size: 18,
              color: AppColorsManger.textSecondary,
            ),
            IconButton(
              onPressed: isBusy ? null : onDelete,
              icon: const Icon(
                Icons.delete_outline,
                color: AppColorsManger.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
