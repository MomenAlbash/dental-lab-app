import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/core/widgets/stage_assignees_sheet.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/logic/workflow_editor/case_stage_groups.dart';
import 'package:dental_lab_app/features/case_stages/logic/workflow_editor/workflow_editor_cubit.dart';
import 'package:dental_lab_app/features/case_stages/logic/workflow_editor/workflow_editor_state.dart';
import 'package:dental_lab_app/features/case_stages/ui/widgets/workflow_stage_card.dart';
import 'package:dental_lab_app/features/case_stages/ui/widgets/stage_order_sheet.dart';
import 'package:dental_lab_app/features/case_stages/ui/widgets/workflow_stage_form_sheet.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The laboratory's case-workflow editor.
///
/// A list, not a canvas. The spec draws this as a graph on the web dashboard,
/// which has the width for it; on a phone "which stages may follow this one"
/// is answered better by a checklist than by a drawing the user has to pan and
/// pinch. The data is identical either way — the edge set is the workflow.
class CaseWorkflowEditorPage extends StatelessWidget {
  const CaseWorkflowEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WorkflowEditorCubit>()..load(),
      child: const _EditorView(),
    );
  }
}

/// Opens the stage form and saves the result. Shared by the "add" action in
/// the app bar and the edit button on each card.
Future<void> _openStageForm(
  BuildContext context, {
  CaseStageModel? stage,
  required int nextOrder,
  required List<CaseStageModel> allStages,
}) async {
  final cubit = context.read<WorkflowEditorCubit>();

  final body = await showWorkflowStageFormSheet(
    context,
    initial: stage,
    nextOrder: nextOrder,
    allStages: allStages,
  );
  if (body == null) return;

  await cubit.saveStage(id: stage?.id, body: body);
}

/// Edits who staffs one stage, without opening the rules.
///
/// Goes out on `PUT /case-statuses/{id}/assignments` rather than the full save
/// — a roster changes far more often than the workflow does, and routing it
/// through the whole body would make every staffing edit a chance to clobber
/// rules the person editing the roster never meant to touch.
Future<void> _editAssignees(BuildContext context, CaseStageModel stage) async {
  final cubit = context.read<WorkflowEditorCubit>();

  final picked = await showStageAssigneesSheet(
    context,
    initial: (
      departmentIds: stage.departmentIds,
      userIds: stage.userIds,
      // `PUT /assignments` carries no exclusion list, so the sheet's third
      // pool is not part of this narrow edit — it stays on the full form.
      excludedUserIds: const <String>[],
    ),
  );
  if (picked == null) return;

  await cubit.setAssignments(
    id: stage.id,
    departmentIds: picked.departmentIds,
    userIds: picked.userIds,
  );
}

Future<void> _deleteStage(BuildContext context, CaseStageModel stage) async {
  final cubit = context.read<WorkflowEditorCubit>();

  // A stage carrying cases cannot be deleted. The cubit says so with the
  // count and suggests deactivating instead — no point making the user
  // confirm a destructive action that is going to be refused.
  if (stage.caseCount > 0) {
    await cubit.deleteStage(stage);
    return;
  }

  final confirmed = await ConfirmDialogWidget.show(
    context,
    title: 'حذف المرحلة',
    message:
        'سيتم حذف "${stage.displayName}" وكل الانتقالات المتصلة بها. متابعة؟',
    confirmText: 'حذف',
    isDestructive: true,
  );
  if (confirmed != true) return;

  await cubit.deleteStage(stage);
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView>
    with SingleTickerProviderStateMixin {
  /// The intake each tab stands for. `null` first: a lab drawing a workflow
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

  /// The doctor-facing buckets a stage can be filed under, loaded once and
  /// handed to the form rather than re-requested per sheet.

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.caseWorkflow,
    );

    return BlocConsumer<WorkflowEditorCubit, WorkflowEditorState>(
      listener: (context, state) {
        if (state is WorkflowEditorMessage) {
          showToast(
            message: state.message,
            state: state.isError ? ToastState.error : ToastState.success,
          );
        }
      },
      builder: (context, state) {
        final loaded = state is WorkflowEditorLoaded ? state : null;

        return GlassScaffold(
          drawer: const AppDrawerWidget(
            currentRoute: Routes.caseWorkflowEditorScreen,
          ),
          appBar: GlassAppBar(
            title: Text(
              'مسار العمل',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            actions: [
              // Ordering is the flow: the API keeps no transition table, so a
              // case runs its intake's stages by `order`. This is where that
              // order is set.
              if (loaded != null && canEdit)
                IconButton(
                  tooltip: 'ترتيب المراحل',
                  onPressed: loaded.isBusy
                      ? null
                      : () async {
                          final saved = await showStageOrderSheet(
                            context,
                            stages: loaded.stages,
                          );
                          if (saved == true && context.mounted) {
                            context.read<WorkflowEditorCubit>().load();
                          }
                        },
                  icon: const Icon(Icons.swap_vert),
                ),
              if (loaded != null && canEdit)
                IconButton(
                  tooltip: 'إضافة مرحلة',
                  onPressed: loaded.isBusy
                      ? null
                      : () => _openStageForm(
                          context,
                          nextOrder: loaded.stages.length,
                          allStages: loaded.stages,
                        ),
                  icon: const Icon(Icons.add),
                ),
              const SizedBox(width: AppSpacing.sm),
            ],
            // The intake fork, named. The workflow carries an impression head
            // and a scanner head and the server prunes one of them, so "which
            // of these stages does a scanned case actually see" is a question
            // the editor has to be able to answer.
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
              WorkflowEditorError(:final message) => _Message(text: message),
              WorkflowEditorLoaded() => _Body(
                state: state,
                canEdit: canEdit,
                intake: _tabs[_tabController.index],
              ),
              _ => const _Skeleton(),
            },
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.canEdit,
    required this.intake,
  });

  final WorkflowEditorLoaded state;
  final bool canEdit;

  /// Null shows the whole workflow; a value prunes the head the server would
  /// prune for a case taken in that way.
  final ImpressionMethod? intake;

  /// Passed through to the stage form's category picker.

  @override
  Widget build(BuildContext context) {
    if (state.stages.isEmpty) return _EmptyWorkflow(canEdit: canEdit);

    // One running order, not bands: the API has no placement field and no
    // transition table, so a case simply runs the stages of its intake from
    // the lowest `order` to the highest.
    final ordered = [
      for (final stage in state.stages)
        if (intake == null || stage.appliesToIntake(intake)) stage,
    ]..sort((a, b) => a.order.compareTo(b.order));

    if (ordered.isEmpty) {
      // Distinct from "this lab has drawn no workflow": it has one, none of it
      // applies to this intake. Saying "empty" would read as data loss.
      return _Message(
        text: 'لا توجد مرحلة في هذا المسار تنطبق على ${intake!.label}',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        if (state.issues.isNotEmpty) ...[
          _IssueSummary(state: state),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
        // The two halves of the workflow, split by the production barrier:
        // an "after" stage does not open until every restoration is finished.
        for (final group in groupStagesByTiming(ordered)) ...[
          GlassSectionTitle(group.title, count: group.stages.length),
          if (group.note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                group.note!,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: context.glass.onGlassMuted,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          for (final stage in group.stages) ...[
            // The position is the running order across the whole workflow, not
            // within the group: a case does not restart counting when it
            // crosses from one category into the next.
            _OrderedStageRow(
              position: ordered.indexOf(stage) + 1,
              child: WorkflowStageCard(
                stage: stage,
                issues: state.issuesFor(stage.id),
                onEdit: () => _openStageForm(
                  context,
                  stage: stage,
                  nextOrder: stage.order,
                  allStages: state.stages,
                ),
                onDelete: () => _deleteStage(context, stage),
                onEditAssignees: () => _editAssignees(context, stage),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        // Production sits between the two halves and is not a stage anyone
        // draws — saying so stops it reading as a gap in the workflow.
        const _ProductionNote(),
      ],
    );
  }
}

class _ProductionNote extends StatelessWidget {
  const _ProductionNote();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: glass.accentSurface,
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.precision_manufacturing_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'بين النصفين يقع الإنتاج: التعويضات تمشي على مسارات أنواعها، '
              'ومراحل ما بعد الإنتاج تُفتح تلقائياً عند انتهاء آخر تعويض.',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueSummary extends StatelessWidget {
  const _IssueSummary({required this.state});

  final WorkflowEditorLoaded state;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final errors = state.errors.length;
    final warnings = state.issues.length - errors;
    final color = errors > 0 ? glass.error : glass.warning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        children: [
          Icon(Icons.rule, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              [
                if (errors > 0) '$errors خطأ',
                if (warnings > 0) '$warnings تنبيه',
              ].join(' · '),
              style: AppTextStyles.font13MediumPrimary.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkflow extends StatelessWidget {
  const _EmptyWorkflow({required this.canEdit});

  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_outlined, size: 44, color: glass.onGlassMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لم يُرسم مسار عمل بعد',
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'لن تتحرك أي حالة حتى يوجد مسار. ابدأ بمسار جاهز ثم عدّله.',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
            if (canEdit) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () =>
                    context.read<WorkflowEditorCubit>().seedDefaults(),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('إنشاء مسار مبدئي'),
              ),
            ],
          ],
        ),
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
      GlassSkeletonBox(height: 160),
      SizedBox(height: AppSpacing.md),
      GlassSkeletonBox(height: 160),
    ],
  );
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

/// Numbers a stage row with its position in the running order.
///
/// The order *is* the workflow now — a case moves from one stage to the next
/// one that applies to its intake — so a row without its number leaves the
/// user counting down the list to answer "which comes first".
class _OrderedStageRow extends StatelessWidget {
  const _OrderedStageRow({required this.position, required this.child});

  final int position;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(
            '$position',
            style: AppTextStyles.font14MediumText.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: child),
      ],
    );
  }
}
