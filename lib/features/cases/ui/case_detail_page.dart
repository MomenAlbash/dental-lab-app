import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/logic/case_details/case_details_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_details/case_details_state.dart';
import 'package:dental_lab_app/features/cases/logic/case_messages/case_messages_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_details_body.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_messages_tab.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_progress_tab.dart';
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
      builder: (_) => _ChangeStageDialog(
        stages: stages,
        currentStageId: restoration.currentStageId,
      ),
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
      length: 3,
      child: GlassScaffold(
        appBar: GlassAppBar(
          title: Text(
            'تفاصيل الحالة',
            style: AppTextStyles.font18MediumText.copyWith(
              color: context.glass.onGlass,
            ),
          ),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: context.glass.onGlassMuted,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'التفاصيل'),
              Tab(text: 'تقدم الحالة'),
              Tab(text: 'المراسلة'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildDetailsTab(context),
              _buildProgressTab(context),
              CaseMessagesTab(caseId: caseId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTab(BuildContext context) {
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
            CaseProgressTab(
              caseDetail: caseDetail,
              isBusy: isBusy,
              onChangeStatus: (status, {note}) => context
                  .read<CaseDetailsCubit>()
                  .setCaseStatus(status: status, note: note),
              onAdvanceStage: (restoration, stageId) =>
                  context.read<CaseDetailsCubit>().setRestorationStage(
                    restorationId: restoration.id,
                    stageId: stageId,
                  ),
            ),
          CaseDetailsError(:final message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: context.glass.onGlassMuted,
                ),
              ),
            ),
          ),
          _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
        };
      },
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
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: context.glass.onGlassMuted,
                ),
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
/// an optional note. Stages are listed in workflow order and annotated so the
/// user can tell where the restoration currently sits and what comes next.
class _ChangeStageDialog extends StatefulWidget {
  const _ChangeStageDialog({required this.stages, this.currentStageId});

  final List<CaseWorkflowStageModel> stages;
  final String? currentStageId;

  @override
  State<_ChangeStageDialog> createState() => _ChangeStageDialogState();
}

class _ChangeStageDialogState extends State<_ChangeStageDialog> {
  String? _stageId;
  String? _error;
  final _noteController = TextEditingController();

  /// Active stages in workflow order — the order the backend expects.
  late final List<CaseWorkflowStageModel> _orderedStages = () {
    final stages = widget.stages.where((s) => s.isActive).toList();
    stages.sort((a, b) => a.order.compareTo(b.order));
    return stages;
  }();

  int get _currentIndex =>
      _orderedStages.indexWhere((s) => s.id == widget.currentStageId);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _labelFor(int index, CaseWorkflowStageModel stage) {
    final name = stage.name ?? '—';
    if (index == _currentIndex) return '$name (الحالية)';
    if (_currentIndex >= 0 && index == _currentIndex + 1) {
      return '$name (التالية)';
    }
    return name;
  }

  void _onConfirm() {
    if (_stageId == null) {
      setState(() => _error = 'اختر المرحلة أولاً');
      return;
    }
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
      // A bounded width is required because AlertDialog measures its content's
      // intrinsic width, which the lookup dropdown's lazy list can't provide.
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CaseLookupDropdown(
                value: _stageId,
                icon: Icons.timeline_outlined,
                hintText: _orderedStages.isEmpty
                    ? 'لا يوجد مراحل لهذا التعويض'
                    : 'اختر المرحلة',
                items: [
                  for (int i = 0; i < _orderedStages.length; i++)
                    DropdownMenuItem(
                      value: _orderedStages[i].id,
                      child: Text(_labelFor(i, _orderedStages[i])),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _stageId = value;
                  _error = null;
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: context.glass.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              AppTextFormField(
                controller: _noteController,
                hintText: 'ملاحظة (اختياري)',
                prefixIcon: Icon(
                  Icons.notes_outlined,
                  color: context.glass.onGlassMuted,
                ),
                validator: (_) => null,
              ),
            ],
          ),
        ),
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
