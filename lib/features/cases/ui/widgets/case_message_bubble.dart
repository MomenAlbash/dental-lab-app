import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/cases/data/models/case_message_attachment_type.dart';
import 'package:dental_lab_app/features/cases/data/models/case_message_model.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/audio_message_player.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// One message bubble in the case conversation — aligned right for the
/// lab's own messages, left for the other side's (doctor).
class CaseMessageBubble extends StatelessWidget {
  const CaseMessageBubble({super.key, required this.message, required this.isMine});

  final CaseMessageModel message;
  final bool isMine;

  Future<void> _openAttachment() async {
    final url = resolveMediaUrl(message.attachmentPath);
    if (url == null) return;
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      ShowToast(message: 'تعذّر فتح المرفق', state: toastState.error);
    }
  }

  Widget _attachment() {
    final url = resolveMediaUrl(message.attachmentPath);
    if (url == null) return const SizedBox.shrink();

    switch (message.attachmentType) {
      case CaseMessageAttachmentType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: _openAttachment,
            child: Image.network(
              url,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
            ),
          ),
        );
      case CaseMessageAttachmentType.audio:
        return AudioMessagePlayer(url: url);
      case CaseMessageAttachmentType.video:
      case CaseMessageAttachmentType.file:
      case null:
        return InkWell(
          onTap: _openAttachment,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColorsManger.moreLightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  message.attachmentType == CaseMessageAttachmentType.video
                      ? Icons.videocam_outlined
                      : Icons.attach_file,
                  size: 18,
                  color: AppColorsManger.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    message.attachmentFileName ?? 'مرفق',
                    style: AppTextStyles.font12RegularHint,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  String _time(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final hasAttachment = message.attachmentPath != null;
    final hasText = (message.message ?? '').trim().isNotEmpty;

    return Align(
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMine ? AppColorsManger.primarySurface : AppColorsManger.moreLightGray,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName ?? 'الطبيب',
                  style: AppTextStyles.font13MediumPrimary,
                ),
              ),
            if (hasAttachment) _attachment(),
            if (hasAttachment && hasText) const SizedBox(height: 6),
            if (hasText)
              Text(message.message!, style: AppTextStyles.font14MediumText),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                _time(message.sentAt),
                style: AppTextStyles.font12RegularHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
