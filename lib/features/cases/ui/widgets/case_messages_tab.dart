import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/cases/logic/case_messages/case_messages_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_messages/case_messages_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_message_bubble.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/voice_recorder_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tab 2 of the case detail screen — conversation between the lab and the
/// doctor for this case (text, images, videos, files and voice notes).
class CaseMessagesTab extends StatefulWidget {
  const CaseMessagesTab({super.key, required this.caseId});

  final String caseId;

  @override
  State<CaseMessagesTab> createState() => _CaseMessagesTabState();
}

class _CaseMessagesTabState extends State<CaseMessagesTab> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _pendingFilePath;

  String? get _myUserId => CacheHelper.getData(key: CacheKeys.userId) as String?;

  @override
  void initState() {
    super.initState();
    context.read<CaseMessagesCubit>().getMessages(widget.caseId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles();
    final path = result?.files.single.path;
    if (path != null) setState(() => _pendingFilePath = path);
  }

  void _send() {
    final text = _messageController.text.trim();
    final filePath = _pendingFilePath;
    if (text.isEmpty && filePath == null) return;

    context.read<CaseMessagesCubit>().sendMessage(
      message: text.isEmpty ? null : text,
      filePath: filePath,
    );
    _messageController.clear();
    setState(() => _pendingFilePath = null);
    _scrollToBottom();
  }

  void _sendVoice(String path) {
    context.read<CaseMessagesCubit>().sendMessage(filePath: path);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CaseMessagesCubit, CaseMessagesState>(
      listenWhen: (previous, current) => current is CaseMessagesActionError,
      listener: (context, state) {
        if (state case CaseMessagesActionError(:final message)) {
          ShowToast(message: message, state: toastState.error);
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            Expanded(child: _buildList(state)),
            if (_pendingFilePath != null) _buildPendingFile(),
            _buildComposer(state),
          ],
        );
      },
    );
  }

  Widget _buildList(CaseMessagesState state) {
    switch (state) {
      case CaseMessagesLoading():
      case CaseMessagesInitial():
        return const Center(child: CustomCircleProgressIndiacatorWidget());
      case CaseMessagesError(:final message):
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        );
      case CaseMessagesLoaded(:final messages):
        if (messages.isEmpty) {
          return const Center(child: Text('لا توجد رسائل بعد'));
        }
        _scrollToBottom();
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return CaseMessageBubble(
              message: message,
              isMine: message.senderId == _myUserId,
            );
          },
        );
      case CaseMessagesActionError():
        return const SizedBox.shrink();
    }
  }

  Widget _buildPendingFile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 18, color: AppColorsManger.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _pendingFilePath!.split(RegExp(r'[\\/]')).last,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _pendingFilePath = null),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(CaseMessagesState state) {
    final isSending = state is CaseMessagesLoaded && state.isSending;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: isSending ? null : _pickFile,
              icon: const Icon(
                Icons.attach_file,
                color: AppColorsManger.textSecondary,
              ),
            ),
            Expanded(
              child: AppTextFormField(
                controller: _messageController,
                hintText: 'اكتب رسالة...',
                validator: (_) => null,
              ),
            ),
            const SizedBox(width: 4),
            if (isSending)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              VoiceRecorderButton(onRecorded: _sendVoice),
              IconButton(
                onPressed: _send,
                icon: const Icon(Icons.send, color: AppColorsManger.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
