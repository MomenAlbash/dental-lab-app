import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_message_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/logic/session_messages/session_messages_cubit.dart';
import 'package:dental_lab_app/features/scanner_sessions/ui/widgets/upload_scan_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The thread between the lab and the doctor about one scanner appointment.
///
/// A sheet rather than a screen: it is always opened *from* a session, and
/// pushing a route would lose the row the user was reading when they come
/// back. Opening it marks the doctor's messages read — reading is the receipt,
/// not a separate button.
Future<void> showSessionMessagesSheet(
  BuildContext context, {
  required String sessionId,
  required String title,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<SessionMessagesCubit>()..load(sessionId),
      child: _SessionMessagesSheet(sessionId: sessionId, title: title),
    ),
  );
}

class _SessionMessagesSheet extends StatefulWidget {
  const _SessionMessagesSheet({required this.sessionId, required this.title});

  final String sessionId;
  final String title;

  @override
  State<_SessionMessagesSheet> createState() => _SessionMessagesSheetState();
}

class _SessionMessagesSheetState extends State<_SessionMessagesSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(BuildContext context) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Cleared before the request, not after: a send that fails puts the text
    // back from the toast's own message rather than leaving the box stuck
    // while the user waits, and a slow connection must not let the same line
    // be typed over twice.
    _controller.clear();
    await context.read<SessionMessagesCubit>().send(text);
  }

  Future<void> _uploadScan(BuildContext context) async {
    final cubit = context.read<SessionMessagesCubit>();

    final upload = await showUploadScanSheet(context);
    if (upload == null) return;

    await cubit.uploadScan(
      filePath: upload.filePath,
      role: upload.role,
      notes: upload.notes,
      clientUploadKey: upload.clientUploadKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return BlocConsumer<SessionMessagesCubit, SessionMessagesState>(
      listenWhen: (previous, current) =>
          current is SessionMessagesActionError ||
          current is SessionMessagesUploaded,
      listener: (context, state) {
        switch (state) {
          case SessionMessagesActionError(:final message):
            showToast(message: message, state: ToastState.error);
          case SessionMessagesUploaded(:final scan):
            showToast(
              message: 'تم رفع ${scan.displayName}',
              state: ToastState.success,
            );
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! SessionMessagesActionError &&
          current is! SessionMessagesUploaded,
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            // Lifts the composer clear of the keyboard — without it the field
            // the user is typing into sits behind it.
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.font16MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'رفع مسح',
                    onPressed: () => _uploadScan(context),
                    icon: Icon(
                      Icons.upload_file_outlined,
                      color: glass.onGlassMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.45,
                child: switch (state) {
                  SessionMessagesLoaded(:final messages) => messages.isEmpty
                      ? const _EmptyThread()
                      : ListView.builder(
                          // Newest at the bottom, scrolled to on open — a
                          // thread opened at its oldest line is a thread
                          // nobody reads the point of.
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) => _MessageBubble(
                            message: messages[messages.length - 1 - index],
                          ),
                        ),
                  SessionMessagesError(:final message) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                    ),
                  ),
                  _ => const Center(
                    child: CustomCircleProgressIndiacatorWidget(),
                  ),
                },
              ),

              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppTextFormField(
                      controller: _controller,
                      hintText: 'اكتب رسالة…',
                      validator: (_) => null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    // Disabled only while a send is actually in flight, so the
                    // button cannot fire twice on a slow connection.
                    onPressed:
                        state is SessionMessagesLoaded && !state.isSending
                        ? () => _send(context)
                        : null,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ScannerSessionMessageModel message;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isMine ? glass.accentSurface : null,
            gradient: isMine ? null : glass.surfaceGradient,
            borderRadius: BorderRadius.circular(AppRadius.glass),
            border: Border.all(color: glass.strokeColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Named only on the other side's messages: labelling every one
              // of the user's own lines with their own name is noise.
              if (!isMine)
                Text(
                  message.isFromDoctor
                      // A colleague's message is not mine but is still the
                      // lab's — drawing it on the doctor's side would
                      // misattribute what the lab itself promised.
                      ? '${message.displaySender} · الطبيب'
                      : message.displaySender,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              Text(
                message.message ?? '',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlass,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.timeLabel,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                  // A read receipt on the other side's message would be
                  // telling the user they read it themselves.
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 12,
                      color: message.isRead ? glass.info : glass.onGlassMuted,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 40,
            color: glass.onGlassMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'لا توجد رسائل بعد',
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }
}
