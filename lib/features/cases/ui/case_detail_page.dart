import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/logic/case_details/case_details_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_details/case_details_state.dart';
import 'package:dental_lab_app/features/cases/logic/case_messages/case_messages_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_details_body.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_messages_tab.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

/// Case detail screen — view the case, change its stage, and manage
/// attachments.
class CaseDetailPage extends StatelessWidget {
  const CaseDetailPage({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CaseDetailsCubit>()..getCase(caseId)),
        BlocProvider(create: (_) => getIt<CaseMessagesCubit>()),
      ],
      child: _CaseDetailView(caseId: caseId),
    );
  }
}

class _CaseDetailView extends StatelessWidget {
  const _CaseDetailView({required this.caseId});

  final String caseId;

  Future<void> _pickAndUploadFile(BuildContext context) async {
    final cubit = context.read<CaseDetailsCubit>();
    try {
      final result = await FilePicker.pickFiles();
      final path = result?.files.single.path;
      if (path != null) await cubit.uploadFile(path);
    } catch (e) {
      ShowToast(
        message: 'تعذّر فتح منتقي الملفات: $e',
        state: toastState.error,
      );
    }
  }

  Future<void> _openFile(String? filePath) async {
    final url = resolveMediaUrl(filePath);
    if (url == null) {
      ShowToast(message: 'لا يوجد ملف للفتح', state: toastState.error);
      return;
    }

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      ShowToast(message: 'تعذّر فتح الملف', state: toastState.error);
    }
  }

  Future<void> _changeStage(
    BuildContext context,
    CaseRestorationModel restoration,
  ) async {
    final cubit = context.read<CaseDetailsCubit>();
    final stages = restoration.restorationType?.stages ?? const [];
    final result = await showDialog<({String stageId, String? note})>(
      context: context,
      builder: (_) => _ChangeStageDialog(stages: stages),
    );

    if (result != null) {
      await cubit.setRestorationStage(
        restorationId: restoration.id,
        stageId: result.stageId,
        note: result.note,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColorsManger.background,
        appBar: AppBar(
          title: Text('تفاصيل الحالة', style: AppTextStyles.font18MediumText),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'التفاصيل'),
              Tab(text: 'المراسلة'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [_buildDetailsTab(context), CaseMessagesTab(caseId: caseId)],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    return BlocConsumer<CaseDetailsCubit, CaseDetailsState>(
          listenWhen: (previous, current) =>
              current is CaseDetailsActionError ||
              current is CaseDetailsActionSuccess,
          listener: (context, state) {
            switch (state) {
              case CaseDetailsActionSuccess(:final message):
                ShowToast(message: message, state: toastState.success);
              case CaseDetailsActionError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! CaseDetailsActionError &&
              current is! CaseDetailsActionSuccess,
          builder: (context, state) {
            return switch (state) {
              CaseDetailsLoaded(:final caseDetail, :final isBusy) =>
                CaseDetailsBody(
                  caseDetail: caseDetail,
                  isBusy: isBusy,
                  onChangeStage: (restoration) =>
                      _changeStage(context, restoration),
                  onAddFile: () => _pickAndUploadFile(context),
                  onOpenFile: (file) => _openFile(file.filePath),
                  onDeleteFile: (fileId) =>
                      context.read<CaseDetailsCubit>().deleteFile(fileId),
                ),
              CaseDetailsError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary,
                  ),
                ),
              ),
              _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
            };
          },
    );
  }
}

/// Dialog to pick a new stage (from the restoration's type stages) and add
/// an optional note.
class _ChangeStageDialog extends StatefulWidget {
  const _ChangeStageDialog({required this.stages});

  final List<CaseWorkflowStageModel> stages;

  @override
  State<_ChangeStageDialog> createState() => _ChangeStageDialogState();
}

class _ChangeStageDialogState extends State<_ChangeStageDialog> {
  String? _stageId;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_stageId == null) return;
    Navigator.of(context).pop((
      stageId: _stageId!,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تغيير المرحلة', style: AppTextStyles.font18MediumText),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CaseLookupDropdown(
            value: _stageId,
            icon: Icons.timeline_outlined,
            hintText: widget.stages.isEmpty
                ? 'لا يوجد مراحل لهذا التعويض'
                : 'اختر المرحلة',
            items: widget.stages
                .map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name ?? '—'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _stageId = value),
          ),
          const SizedBox(height: 12),
          AppTextFormField(
            controller: _noteController,
            hintText: 'ملاحظة (اختياري)',
            prefixIcon: const Icon(
              Icons.notes_outlined,
              color: AppColorsManger.textSecondary,
            ),
            validator: (_) => null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _onConfirm, child: const Text('تأكيد')),
      ],
    );
  }
}
