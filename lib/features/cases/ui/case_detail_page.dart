import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/case_stages/logic/case_stages/case_stages_cubit.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/logic/case_details/case_details_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_details/case_details_state.dart';
import 'package:dental_lab_app/features/cases/logic/case_messages/case_messages_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_details_body.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/cases/data/models/case_stage_move_model.dart';
import 'package:dental_lab_app/features/cases/logic/case_progress/case_progress_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_progress/case_progress_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_phase_action_card.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_progress_view.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_messages_tab.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_stage_move_sheet.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/restoration_move_sheet.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/trying_reject_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
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
        // The plan is a separate endpoint with its own refresh rhythm; the
        // catalogue supplies the legal moves out of whatever stage is live.
        BlocProvider(create: (_) => getIt<CaseStagesCubit>()..getCaseStages()),
      ],
      child: _CaseDetailView(caseId: caseId),
    );
  }
}

class _CaseDetailView extends StatelessWidget {
  const _CaseDetailView({required this.caseId});

  final String caseId;

  /// Idempotent on the server — a second tap just opens the same invoice
  /// rather than generating a duplicate.
  Future<void> _openInvoice(BuildContext context) async {
    final result = await getIt<AccountingRepo>().createInvoiceFromCase(
      caseId: caseId,
    );

    if (!context.mounted) return;
    result.fold(
      (failure) =>
          showToast(message: failure.errorMessage, state: ToastState.error),
      (invoice) => context.push(Routes.invoiceDetailScreen, extra: invoice.id),
    );
  }

  Future<void> _pickAndUploadFile(BuildContext context) async {
    final cubit = context.read<CaseDetailsCubit>();
    try {
      final result = await FilePicker.pickFiles();
      final path = result?.files.single.path;
      if (path != null) await cubit.uploadFile(path);
    } catch (e) {
      showToast(
        message: 'تعذّر فتح منتقي الملفات: $e',
        state: ToastState.error,
      );
    }
  }

  Future<void> _openFile(String? filePath) async {
    final url = resolveMediaUrl(filePath);
    if (url == null) {
      showToast(message: 'لا يوجد ملف للفتح', state: ToastState.error);
      return;
    }

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      showToast(message: 'تعذّر فتح الملف', state: ToastState.error);
    }
  }

  Future<void> _changeStage(
    BuildContext context,
    CaseRestorationModel restoration, {
    List<CaseWorkflowStageModel>? route,
  }) async {
    final cubit = context.read<CaseDetailsCubit>();
    // The route the progress board already fetched, when the move is started
    // from there. The type carried inline on the case is a summary and can be
    // empty, which used to leave the dialog with nothing to offer.
    final stages = route ?? restoration.restorationType?.stages ?? const [];
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

  /// Opens the move sheet and applies whatever the user picked.
  ///
  /// The options are handed in from the case itself: they are the server's own
  /// answer to what this case may do now, and recomputing them here would
  /// disagree with it the moment the lab edits its workflow.
  /// Moves one restoration along its route, the same way the case moves along
  /// its own: one step forward, or back to a target the server names.
  Future<void> _moveRestoration(
    BuildContext context,
    RestorationProgress progress,
  ) async {
    final cubit = context.read<CaseDetailsCubit>();

    final move = await showRestorationMoveSheet(
      context,
      caseId: caseId,
      restorationId: progress.id,
    );
    if (move == null) return;

    await cubit.setRestorationStage(
      restorationId: progress.id,
      stageId: move.stageId,
      note: move.note,
    );
  }

  /// Walks back an arrival recorded against the wrong case.
  ///
  /// Confirmed first: it puts the case back to `New`, which closes the
  /// workflow the receipt opened — recoverable, but not silently.
  Future<void> _undoReceiveMaterial(BuildContext context) async {
    final cubit = context.read<CaseDetailsCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'التراجع عن الاستلام',
      message:
          'ستعود الحالة إلى "جديدة" ويُغلق مسارها حتى يُسجَّل الاستلام من جديد.',
      confirmText: 'تراجع',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.undoMaterialReceived();
  }

  /// The doctor refused the fit: which pieces, and where each goes back to.
  Future<void> _rejectTrying(
    BuildContext context,
    CaseDetailModel caseDetail,
  ) async {
    final cubit = context.read<CaseDetailsCubit>();

    final result = await showTryingRejectSheet(
      context,
      caseId: caseDetail.id,
      restorations: caseDetail.restorations,
    );
    if (result == null) return;

    await cubit.rejectTrying(
      restorations: result.lines,
      note: result.note,
    );
  }

  Future<void> _moveCaseStage(
    BuildContext context,
    List<CaseStageMoveModel> transitions, {
    Set<String> barredStageIds = const {},
  }) async {
    final cubit = context.read<CaseDetailsCubit>();

    final move = await showCaseStageMoveSheet(
      context,
      transitions: transitions,
      barredStageIds: barredStageIds,
      barredReason: "لا يمكن تجاوز الإنتاج قبل انتهاء كل التعويضات",
    );
    if (move == null) return;

    await cubit.moveStage(
      toStageId: move.toStageId,
      note: move.note,
      rejectionReason: move.rejectionReason,
    );
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
          actions: [
            if (getIt<SessionCubit>().state.canEdit(PermissionName.finance))
              IconButton(
                tooltip: 'الفاتورة',
                icon: const Icon(Icons.receipt_long_outlined),
                onPressed: () => _openInvoice(context),
              ),
            BlocBuilder<CaseDetailsCubit, CaseDetailsState>(
              builder: (context, state) {
                if (state is! CaseDetailsLoaded) {
                  return const SizedBox.shrink();
                }
                return _CasePdfButton(
                  caseId: caseId,
                  caseNumber: state.caseDetail.caseNumber,
                );
              },
            ),
            // The case's own move, distinct from a restoration's: it is the
            // whole case that steps forward here, and what it may do is
            // answered by the server, not computed from the workflow.
            BlocBuilder<CaseDetailsCubit, CaseDetailsState>(
              builder: (context, state) {
                if (state is! CaseDetailsLoaded) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  tooltip: 'نقل الحالة',
                  icon: const Icon(Icons.alt_route),
                  onPressed: state.isBusy
                      ? null
                      : () => _moveCaseStage(
                          context,
                          state.caseDetail.availableTransitions,
                        ),
                );
              },
            ),
          ],
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
    // Composed from the catalogues rather than from a stored plan: the
    // `/Cases/{id}/plan` endpoint this tab used to call was deleted with the
    // graph engine, which is what the 404 on this screen was.
    // Its own listener: the details tab reports its outcomes, and without one
    // here every phase action — recording the material, passing the check —
    // succeeded or failed in complete silence.
    return BlocConsumer<CaseDetailsCubit, CaseDetailsState>(
      listenWhen: (previous, current) =>
          current is CaseDetailsActionError ||
          current is CaseDetailsActionSuccess,
      listener: (context, state) {
        switch (state) {
          case CaseDetailsActionSuccess(:final message):
            showToast(message: message, state: ToastState.success);
          case CaseDetailsActionError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! CaseDetailsActionError &&
          current is! CaseDetailsActionSuccess,
      builder: (context, detailsState) {
        if (detailsState is CaseDetailsError) {
          return _ProgressMessage(text: detailsState.message);
        }
        if (detailsState is! CaseDetailsLoaded) {
          return const Center(child: CustomCircleProgressIndiacatorWidget());
        }

        return BlocProvider(
          // Keyed by the case's own stage: a move rebuilds the board against
          // the position the case just took, without the tab having to
          // subscribe to the details cubit twice.
          key: ValueKey(detailsState.caseDetail.stage.stageId),
          create: (_) =>
              getIt<CaseProgressCubit>()..load(detailsState.caseDetail),
          child: BlocBuilder<CaseProgressCubit, CaseProgressState>(
            builder: (context, state) => switch (state) {
              CaseProgressLoaded() => CaseProgressView(
                state: state,
                onMoveCase: () => _moveCaseStage(
                  context,
                  detailsState.caseDetail.availableTransitions,
                  barredStageIds: state.barredStageIds,
                ),
                onMoveRestoration: (progress) =>
                    _moveRestoration(context, progress),
                phaseCard: CasePhaseActionCard(
                  phase: detailsState.caseDetail.phase,
                  isBusy: detailsState.isBusy,
                  onReceiveMaterial: (note) => context
                      .read<CaseDetailsCubit>()
                      .receiveMaterial(note: note),
                  onPassQualityCheck: (note) => context
                      .read<CaseDetailsCubit>()
                      .passQualityCheck(note: note),
                  onApproveTrying: (note) => context
                      .read<CaseDetailsCubit>()
                      .approveTrying(note: note),
                  onUndoReceiveMaterial: () =>
                      _undoReceiveMaterial(context),
                  onRejectTrying: () =>
                      _rejectTrying(context, detailsState.caseDetail),
                ),
              ),
              CaseProgressError(:final message) => _ProgressMessage(
                text: message,
              ),
              _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
            },
          ),
        );
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
            showToast(message: message, state: ToastState.success);
          case CaseDetailsActionError(:final message):
            showToast(message: message, state: ToastState.error);
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

/// A message where the board would be — an error, or a case with nothing on
/// it yet.
class _ProgressMessage extends StatelessWidget {
  const _ProgressMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.font14RegularSecondary.copyWith(
            color: context.glass.onGlassMuted,
          ),
        ),
      ),
    );
  }
}

/// Downloads and shares the case's PDF (`GET /Reports/cases/{id}/pdf`).
///
/// A small stateful island inside an otherwise stateless page — the busy
/// spinner is local to this one button and has nothing to do with
/// `CaseDetailsCubit.isBusy`, which tracks the case's own stage/upload
/// actions.
class _CasePdfButton extends StatefulWidget {
  const _CasePdfButton({required this.caseId, required this.caseNumber});

  final String caseId;
  final String? caseNumber;

  @override
  State<_CasePdfButton> createState() => _CasePdfButtonState();
}

class _CasePdfButtonState extends State<_CasePdfButton> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);

    final result = await getIt<CasesRepo>().downloadCasePdf(
      id: widget.caseId,
      caseNumber: widget.caseNumber ?? widget.caseId,
    );

    if (!mounted) return;
    setState(() => _downloading = false);

    await result.fold(
      (failure) async =>
          showToast(message: failure.errorMessage, state: ToastState.error),
      // Shared rather than opened directly — a raw file:// launch crashes on
      // Android 7+ without a FileProvider.
      (path) async {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: 'حالة ${widget.caseNumber ?? ''}',
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'PDF الحالة',
      icon: _downloading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      onPressed: _downloading ? null : _download,
    );
  }
}
