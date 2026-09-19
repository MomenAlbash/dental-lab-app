import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_stages/data/models/route_problem_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/repos/workflow_stages_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/workflow_stages/workflow_stages_cubit.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/workflow_stages/workflow_stages_state.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/route_editor/route_editor_cubit.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/route_editor/route_editor_state.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/workflow_stages/route_bands.dart';
import 'package:dental_lab_app/features/case_workflow_stages/ui/widgets/restoration_route_graph.dart';
import 'package:dental_lab_app/features/case_workflow_stages/ui/widgets/restoration_stage_card.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/case_workflow_stages/ui/widgets/workflow_stage_form_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Arguments for [RestorationRouteEditorPage], passed as a route `extra`.
class RestorationRouteEditorArgs {
  const RestorationRouteEditorArgs({
    required this.restorationTypeId,
    required this.restorationTypeName,
  });

  final String restorationTypeId;
  final String restorationTypeName;
}

/// The manufacturing stages of one restoration type's route.
///
/// A separate screen from the case-workflow editor because they are separate
/// things: a case has one workflow drawn per laboratory, while each restoration
/// *type* has its own route. Blending them is the mistake MOBILE-SPEC §17.1
/// warns about.
class RestorationRouteEditorPage extends StatelessWidget {
  const RestorationRouteEditorPage({super.key, required this.args});

  final RestorationRouteEditorArgs args;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<WorkflowStagesCubit>()
                ..load(restorationTypeId: args.restorationTypeId),
        ),
        // The server's own live verdict on the route — computed on every
        // load, not only on a save button, and shown beside the stages.
        BlocProvider(
          create: (_) =>
              getIt<RouteEditorCubit>()..load(args.restorationTypeId),
        ),
      ],
      child: _RouteEditorView(args: args),
    );
  }
}

class _RouteEditorView extends StatefulWidget {
  const _RouteEditorView({required this.args});

  final RestorationRouteEditorArgs args;

  @override
  State<_RouteEditorView> createState() => _RouteEditorViewState();
}

class _RouteEditorViewState extends State<_RouteEditorView>
    with SingleTickerProviderStateMixin {
  /// The intake each tab stands for. `null` first: a lab drawing a route
  /// wants to see all of it before it asks what one head looks like.
  static const List<ImpressionMethod?> _tabs = [
    null,
    ImpressionMethod.traditional,
    ImpressionMethod.digital,
  ];

  late final TabController _tabController = TabController(
    length: _tabs.length,
    vsync: this,
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openForm({
    CaseWorkflowStageModel? stage,
    required int nextOrder,
    required List<CaseWorkflowStageModel> allStages,
  }) async {
    final cubit = context.read<WorkflowStagesCubit>();

    final result = await showRestorationStageFormSheet(
      context,
      initial: stage,
      restorationTypeId: widget.args.restorationTypeId,
      nextOrder: nextOrder,
      allStages: allStages,
    );
    if (result == null) return;

    if (result.create case final body?) {
      await cubit.createStage(body);
    } else if (result.update case final body?) {
      await cubit.updateStage(id: stage!.id, body: body);
    }
  }

  /// The full card, opened by tapping a node.
  ///
  /// A graph node is too small to carry the details and the three actions, and
  /// widening it to fit them would cost the shape the graph exists for. The
  /// card that used to be the whole list is reused here unchanged.
  Future<void> _openStage(
    CaseWorkflowStageModel stage,
    List<CaseWorkflowStageModel> allStages,
  ) async {
    final cubit = context.read<WorkflowStagesCubit>();

    await showGlassBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: RestorationStageCard(
          stage: stage,
          onEdit: () {
            Navigator.of(sheetContext).pop();
            _openForm(
              stage: stage,
              nextOrder: stage.order,
              allStages: allStages,
            );
          },
          onDeactivate: () {
            Navigator.of(sheetContext).pop();
            cubit.deactivateStage(stage);
          },
          onChangeImage: () {
            Navigator.of(sheetContext).pop();
            _changeStageImage(stage);
          },
          onDelete: () {
            Navigator.of(sheetContext).pop();
            _delete(stage);
          },
        ),
      ),
    );
  }

  /// Replaces the backdrop this stage shows the bench.
  ///
  /// A work reference — the diagram or photo a technician checks against —
  /// not the restoration type's catalogue shot, which lives on the
  /// doctor-facing website and is a different image for a different reader.
  Future<void> _changeStageImage(CaseWorkflowStageModel stage) async {
    final cubit = context.read<WorkflowStagesCubit>();

    final result = await FilePicker.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;

    final uploaded = await getIt<WorkflowStagesRepo>().uploadStageImage(
      id: stage.id,
      filePath: path,
    );
    if (!mounted) return;

    await uploaded.fold(
      (failure) async =>
          showToast(message: failure.errorMessage, state: ToastState.error),
      (_) async {
        showToast(message: 'تم تحديث صورة المرحلة', state: ToastState.success);
        await cubit.load();
      },
    );
  }

  Future<void> _delete(CaseWorkflowStageModel stage) async {
    final cubit = context.read<WorkflowStagesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف المرحلة',
      message:
          'سيتم حذف "${stage.displayName}" من مسار هذا التعويض. '
          'إن كانت مستخدمة على تعويضات جارية فالأفضل تعطيلها بدل حذفها.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.deleteStage(stage.id);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.caseWorkflow,
    );

    return BlocConsumer<WorkflowStagesCubit, WorkflowStagesState>(
      listener: (context, state) {
        if (state is WorkflowStagesMessage) {
          showToast(
            message: state.message,
            state: state.isError ? ToastState.error : ToastState.success,
          );
        }
      },
      builder: (context, state) {
        final loaded = state is WorkflowStagesLoaded ? state : null;

        return GlassScaffold(
          appBar: GlassAppBar(
            title: Text(
              'مسار ${widget.args.restorationTypeName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            actions: [
              if (loaded != null && canEdit)
                IconButton(
                  tooltip: 'إضافة مرحلة',
                  onPressed: loaded.isBusy
                      ? null
                      : () => _openForm(
                          nextOrder: loaded.stages.length,
                          allStages: loaded.stages,
                        ),
                  icon: const Icon(Icons.add),
                ),
              const SizedBox(width: AppSpacing.sm),
            ],
            // The intake fork, named. A route carries a traditional head and a
            // digital head and the server prunes one of them, so "which of
            // these stages does a scanned case actually see" is a question the
            // editor has to be able to answer — a single mixed list could not.
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'كل المراحل'),
                Tab(text: 'طبعة تقليدية'),
                Tab(text: 'مسح رقمي'),
              ],
            ),
          ),
          body: SafeArea(
            child: switch (state) {
              WorkflowStagesError(:final message) => _Message(text: message),
              WorkflowStagesLoaded(:final stages) =>
                stages.isEmpty
                    ? const _Empty()
                    : _RouteBody(
                        stages: stages,
                        intake: _tabs[_tabController.index],
                        onStageTap: (stage) => _openStage(stage, stages),
                      ),
              _ => const _Skeleton(),
            },
          ),
        );
      },
    );
  }
}

/// The route drawn from its stages' own `order`, with the server's live
/// verdict on top.
class _RouteBody extends StatelessWidget {
  const _RouteBody({
    required this.stages,
    required this.intake,
    required this.onStageTap,
  });

  final List<CaseWorkflowStageModel> stages;
  final ImpressionMethod? intake;
  final ValueChanged<CaseWorkflowStageModel> onStageTap;

  @override
  Widget build(BuildContext context) {
    final bands = RouteBands.build(stages, intake: intake);

    if (bands.isEmpty) {
      // Distinct from "this route has no stages": the route has stages,
      // none of them are cut for this intake. Saying "empty" would read as
      // data loss.
      return _Message(
        text: intake == null
            ? 'لا توجد مراحل فعّالة في هذا المسار'
            : 'لا توجد مرحلة في هذا المسار تنطبق على ${intake!.label}',
      );
    }

    return BlocBuilder<RouteEditorCubit, RouteEditorState>(
      builder: (context, state) {
        final problems = state is RouteEditorLoaded
            ? state.route.problems
            : const <RouteProblemModel>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The server's own verdict, not the app's guess. It decides
              // whether production can run this route at all.
              if (problems.isNotEmpty) ...[
                _Problems(problems: problems),
                const SizedBox(height: AppSpacing.md),
              ],
              RestorationRouteGraph(bands: bands, onStageTap: onStageTap),
            ],
          ),
        );
      },
    );
  }
}

/// What the server says is wrong with the route.
class _Problems extends StatelessWidget {
  const _Problems({required this.problems});

  final List<RouteProblemModel> problems;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: glass.error.withValues(alpha: 0.10),
        border: Border.all(color: glass.error.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 18, color: glass.error),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'مشاكل في المسار (${problems.length})',
                style: AppTextStyles.font13MediumPrimary.copyWith(
                  color: glass.error,
                ),
              ),
            ],
          ),
          for (final problem in problems) ...[
            const SizedBox(height: 6),
            Text(
              '• ${problem.displayMessage}',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlass,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screen),
    children: const [
      GlassSkeletonBox(height: 130),
      SizedBox(height: AppSpacing.md),
      GlassSkeletonBox(height: 130),
    ],
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.precision_manufacturing_outlined,
              size: 44,
              color: glass.onGlassMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد مراحل تصنيع لهذا التعويض',
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'التعويض بلا مسار لن يتحرك في الإنتاج.',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
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
