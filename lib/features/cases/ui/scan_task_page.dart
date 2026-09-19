import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/logic/scan_task/scan_task_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/scan_task/scan_task_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Route arguments for [ScanTaskPage].
///
/// Two values rather than a bare id: the scanner has already fetched the case
/// to resolve the barcode, and making the next screen fetch it again would
/// cost a second round trip on a phone standing at a bench.
class ScanTaskArgs {
  const ScanTaskArgs({required this.caseDetail, required this.restorationId});

  final CaseDetailModel caseDetail;
  final String restorationId;
}

/// What a scanned piece asks of the person holding it.
///
/// The shop-floor screen: a technician points the camera at the sticker on a
/// unit and lands here, on one question — "this is your stage, done with it?"
/// — rather than on the full case sheet, which is a manager's screen and
/// mostly redacted for them anyway.
///
/// Reaching it does **not** mean the stage is theirs to move. Nothing in the
/// API says who may work a stage ahead of time, so the button is offered and
/// the server's `403` is shown as a calm "not your stage", not as a failure.
class ScanTaskPage extends StatelessWidget {
  const ScanTaskPage({
    super.key,
    required this.caseDetail,
    required this.restorationId,
  });

  final CaseDetailModel caseDetail;
  final String restorationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ScanTaskCubit>()
            ..load(caseDetail: caseDetail, restorationId: restorationId),
      child: const _ScanTaskView(),
    );
  }
}

class _ScanTaskView extends StatelessWidget {
  const _ScanTaskView();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'المهمة',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<ScanTaskCubit, ScanTaskState>(
          builder: (context, state) => switch (state) {
            ScanTaskLoading() => const Center(
              child: CustomCircleProgressIndiacatorWidget(),
            ),
            ScanTaskError(:final message) => _Message(text: message),
            ScanTaskReady() => _Body(state: state),
          },
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.state});

  final ScanTaskReady state;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Asked before the move because it cannot be taken back from this screen:
  /// the piece leaves this person's hands and lands on the next stage's pool.
  Future<void> _confirmAndComplete() async {
    final state = widget.state;
    final stageName = state.currentStageName;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الإنجاز'),
        content: Text(
          stageName == null || stageName.isEmpty
              ? 'هل أنجزت العمل على هذا التعويض؟ سينتقل إلى ${state.nextStageLabel}.'
              : 'هل أنجزت مرحلة "$stageName"؟ سينتقل التعويض إلى ${state.nextStageLabel}.',
          style: AppTextStyles.font14RegularSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('نعم، أنجزتها'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final note = _noteController.text.trim();
    await context.read<ScanTaskCubit>().completeStage(
      note: note.isEmpty ? null : note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Capped and centred: this is a single short form, and a full-width
        // one on a tablet reads as a mis-laid-out page.
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PieceCard(state: state),
                  const SizedBox(height: AppSpacing.lg),

                  if (state.isDone)
                    const _DoneCard()
                  else if (state.refusal != null)
                    _RefusalCard(message: state.refusal!)
                  else if (state.isAtEndOfRoute)
                    const _Notice(
                      icon: Icons.flag_outlined,
                      text:
                          'هذا التعويض وصل إلى نهاية مساره — لا توجد مرحلة تالية.',
                    )
                  else ...[
                    _NoteField(controller: _noteController),
                    const SizedBox(height: AppSpacing.md),
                    _CompleteButton(
                      state: state,
                      onPressed: _confirmAndComplete,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                  TextButton.icon(
                    onPressed: () => context.pushReplacement(
                      Routes.caseDetailScreen,
                      extra: state.caseDetail.id,
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('عرض تفاصيل الحالة'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The piece, named — what the technician is holding and where it stands.
class _PieceCard extends StatelessWidget {
  const _PieceCard({required this.state});

  final ScanTaskReady state;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;
    final restoration = state.restoration;
    final stageName = state.currentStageName;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glassLg),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: glass.brandGradient,
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restoration.restorationName,
                      style: AppTextStyles.font18MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (restoration.restorationNumber != null)
                      Text(
                        'رقم القطعة: ${restoration.restorationNumber}',
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: glass.strokeColor, height: 1),
          const SizedBox(height: AppSpacing.md),

          _Line(
            label: 'الحالة',
            value: state.caseDetail.caseNumber == null
                ? '—'
                : 'رقم ${state.caseDetail.caseNumber}',
          ),
          if ((state.caseDetail.patientName ?? '').isNotEmpty)
            _Line(label: 'المريض', value: state.caseDetail.patientName!),

          const SizedBox(height: AppSpacing.md),
          Text(
            'المرحلة الحالية',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            // Never invented: when neither the response nor the route named
            // the stage, that is said plainly. The move can still be tried,
            // and the server's answer names it.
            stageName == null || stageName.isEmpty ? 'غير معروفة' : stageName,
            style: AppTextStyles.font18MediumText.copyWith(
              color: stageName == null || stageName.isEmpty
                  ? glass.onGlassMuted
                  : accent,
            ),
          ),

          if (state.hasNextStep) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.arrow_downward, size: 14, color: glass.onGlassMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'التالية: ${state.nextStageLabel}',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.font14MediumText.copyWith(
                color: glass.onGlass,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.glass),
      borderSide: BorderSide(color: glass.strokeColor),
    );

    return TextField(
      controller: controller,
      maxLines: 2,
      style: AppTextStyles.font14MediumText.copyWith(color: glass.onGlass),
      decoration: InputDecoration(
        filled: true,
        fillColor: glass.fillColor,
        hintText: 'ملاحظة (اختياري)',
        hintStyle: AppTextStyles.font14RegularSecondary.copyWith(
          color: glass.onGlassMuted,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.6,
          ),
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({required this.state, required this.onPressed});

  final ScanTaskReady state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: state.isSubmitting ? null : onPressed,
        icon: state.isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline),
        label: Text(
          state.isSubmitting ? 'جارٍ الإرسال...' : 'إنجاز هذه المرحلة',
          style: AppTextStyles.font16MediumText,
        ),
      ),
    );
  }
}

/// The server said the stage is not this person's.
///
/// Deliberately calm, and deliberately the server's own sentence: it names
/// the stage, which is the one thing the client was never told. Shown as
/// information, not as a red failure — being handed the wrong piece is a
/// normal thing to happen on a shop floor, not a mistake to scold.
class _RefusalCard extends StatelessWidget {
  const _RefusalCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: glass.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pan_tool_outlined, color: glass.warning, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ليست مرحلتك',
                style: AppTextStyles.font16MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'سلّم القطعة للمسؤول عن هذه المرحلة.',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: glass.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: glass.success, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'تم إنجاز المرحلة — انتقل التعويض إلى المرحلة التالية.',
              style: AppTextStyles.font14MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: glass.mutedSurface,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: glass.onGlassMuted, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
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
