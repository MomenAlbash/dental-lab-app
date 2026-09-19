import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_detail_sections.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/scan_storage/data/models/scan_storage_model.dart';
import 'package:dental_lab_app/features/scan_storage/logic/scan_storage/scan_storage_cubit.dart';
import 'package:dental_lab_app/features/scan_storage/ui/widgets/nas_archive_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the laboratory's scans are costing it in disk, and the two ways to
/// free some.
///
/// Every figure is the server's. Nothing here recomputes eligibility or usage
/// from a date and a day count — a screen that disagreed with the sweep that
/// actually runs would be promising deletions that never happen.
class ScanStoragePage extends StatelessWidget {
  const ScanStoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScanStorageCubit>()..load(),
      child: const _ScanStorageView(),
    );
  }
}

class _ScanStorageView extends StatelessWidget {
  const _ScanStorageView();

  Future<void> _runSweep(BuildContext context, ScanStorageModel storage) async {
    final cubit = context.read<ScanStorageCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'تشغيل التنظيف',
      message:
          'سيُحذف ${storage.eligibleNowCount} ملف مسح '
          '(${storage.eligibleNowLabel}) بحسب قواعد الحفظ عندكم. '
          'السجلات بتضل — الملفات بس بتنحذف.',
      confirmText: 'تشغيل',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.runSweep();
  }

  Future<void> _removeFile(
    BuildContext context,
    StoredScanModel scan,
  ) async {
    final cubit = context.read<ScanStorageCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الملف',
      message:
          'سيُحذف ملف "${scan.displayName}" (${scan.sizeLabel}) نهائياً. '
          'سجل المسح بيضل على الطلب.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.removeFile(scan.id);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    // Storage is a laboratory-wide setting, so it follows the branches
    // permission rather than the case one.
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.branches,
    );

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.scanStorageScreen),
      appBar: GlassAppBar(
        title: Text(
          'مساحة المسوحات',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ScanStorageCubit, ScanStorageState>(
          listenWhen: (previous, current) =>
              current is ScanStorageActionError ||
              current is ScanStorageRunFinished,
          listener: (context, state) {
            switch (state) {
              case ScanStorageActionError(:final message):
                showToast(message: message, state: ToastState.error);
              case ScanStorageRunFinished(:final result):
                showToast(
                  message: _runMessage(result),
                  // Still over budget is not a success, however many files
                  // went — a bare "removed 12" would read like one.
                  state: result.stillOverBudget
                      ? ToastState.warning
                      : ToastState.success,
                );
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! ScanStorageActionError &&
              current is! ScanStorageRunFinished,
          builder: (context, state) => switch (state) {
            ScanStorageLoaded() => _Body(
              state: state,
              canEdit: canEdit,
              onRunSweep: () => _runSweep(context, state.storage),
              onRemoveFile: (scan) => _removeFile(context, scan),
            ),
            ScanStorageError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ),
            ),
            _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
          },
        ),
      ),
    );
  }

  static String _runMessage(ScanRetentionRunResultModel result) {
    final parts = [
      'حُذف ${result.removedCount} ملف (${result.reclaimedLabel})',
      // Not an error — the database and the filesystem disagreeing, usually
      // after a restore — but said, because those rows freed nothing and the
      // numbers will not add up otherwise.
      if (result.missingFileCount > 0)
        '${result.missingFileCount} ملف كان مفقوداً أصلاً',
      if (result.stillOverBudget) 'ما زلنا فوق الحد',
    ];
    return parts.join(' · ');
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.canEdit,
    required this.onRunSweep,
    required this.onRemoveFile,
  });

  final ScanStorageLoaded state;
  final bool canEdit;
  final VoidCallback onRunSweep;
  final ValueChanged<StoredScanModel> onRemoveFile;

  @override
  Widget build(BuildContext context) {
    final storage = state.storage;

    return RefreshIndicator(
      onRefresh: () => context.read<ScanStorageCubit>().load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AdaptiveDetailSections(
          main: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LargestStored(
                  scans: storage.largestStored,
                  onRemove: canEdit ? onRemoveFile : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                _RecentRemovals(removals: storage.recentRemovals),
              ],
            ),
          ],
          // What the user can *do* comes before what they read: on a phone
          // this renders first, and an over-budget lab needs the actions, not
          // a table of its biggest files.
          side: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _UsageCard(storage: storage),
                const SizedBox(height: AppSpacing.md),
                _Actions(
                  state: state,
                  canEdit: canEdit,
                  onRunSweep: onRunSweep,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.storage});

  final ScanStorageModel storage;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final barColor = storage.isOverBudget
        ? glass.error
        : (storage.isWarning ? glass.warning : glass.success);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${storage.storedLabel} من ${storage.budgetLabel}',
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              Text(
                '%${storage.usagePercent}',
                style: AppTextStyles.font16MediumText.copyWith(
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: storage.usageFraction,
              minHeight: 8,
              backgroundColor: glass.strokeColor,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          // The state that needs a person: over budget with nothing the rules
          // allow deleting means the sweep cannot help. Silence here is how a
          // lab fills its disk under a green "auto-cleanup on".
          if (storage.overBudgetAndNothingEligible)
            _Notice(
              icon: Icons.report_problem_outlined,
              color: glass.error,
              text:
                  'فوق الحد، ولا يوجد ملف تسمح القواعد بحذفه. '
                  'قصّروا مدة الحفظ، أو ارفعوا الحد، أو أرشفوا على NAS.',
            )
          else if (storage.isOverBudget)
            _Notice(
              icon: Icons.warning_amber_outlined,
              color: glass.error,
              text: 'فوق الحد المسموح',
            )
          else if (storage.isWarning)
            _Notice(
              icon: Icons.info_outline,
              color: glass.warning,
              text: 'تجاوزنا %${storage.warnPercent} من الحد',
            ),

          const SizedBox(height: AppSpacing.md),
          _Stat(label: 'عدد الملفات', value: '${storage.storedCount}'),
          _Stat(
            label: 'مؤهّل للحذف الآن',
            value:
                '${storage.eligibleNowCount} (${storage.eligibleNowLabel})',
          ),
          _Stat(
            label: 'حُرِّر سابقاً',
            value: '${storage.removedCount} (${storage.reclaimedLabel})',
          ),
          // Outside the retention sweep entirely, so a disk full of these will
          // not be helped by running it — which is why it is named, not folded
          // into a single "uploads" figure.
          _Stat(label: 'رفعات أخرى (خارج التنظيف)', value: storage.otherUploadsLabel),
          _Stat(label: 'متبقٍ على القرص', value: storage.diskFreeLabel),
          if (storage.oldestStoredAt != null)
            _Stat(
              label: 'أقدم مسح',
              value: ApiTime.formatDate(storage.oldestStoredAt!),
            ),

          const SizedBox(height: AppSpacing.sm),
          Text(
            storage.retentionEnabled
                ? 'التنظيف التلقائي: بعد ${storage.retentionDays} يوم'
                      '${storage.onlyClosedCases ? '، للطلبات المغلقة فقط' : ''}'
                : 'التنظيف التلقائي متوقف',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.canEdit,
    required this.onRunSweep,
  });

  final ScanStorageLoaded state;
  final bool canEdit;
  final VoidCallback onRunSweep;

  @override
  Widget build(BuildContext context) {
    if (!canEdit) return const SizedBox.shrink();

    final glass = context.glass;
    final storage = state.storage;
    final pending = state.pendingArchive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          // Disabled when a run would free nothing: a cleanup button that
          // reliably does nothing teaches people to stop trusting the screen.
          onPressed: state.isBusy || !storage.hasSomethingToSweep
              ? null
              : onRunSweep,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: Text(
            storage.hasSomethingToSweep
                ? 'تشغيل التنظيف (${storage.eligibleNowCount})'
                : 'لا يوجد ما يُنظَّف',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: state.isBusy || pending.isEmpty
              ? null
              : () => showNasArchiveSheet(context, pending: pending),
          icon: const Icon(Icons.dns_outlined),
          label: Text(
            pending.isEmpty
                ? 'لا يوجد بانتظار الأرشفة'
                : 'أرشفة على NAS (${pending.length})',
          ),
        ),
        if (pending.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              // The two-step flow said plainly, because confirming is what
              // frees the bytes and doing it before the copy loses the scan.
              'انسخوا الملفات على الـ NAS أولاً، وبعدها أكّدوا — التأكيد هو '
              'اللي بيحرّر المساحة.',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _LargestStored extends StatelessWidget {
  const _LargestStored({required this.scans, this.onRemove});

  final List<StoredScanModel> scans;

  /// Null without permission to edit — the action is left off rather than
  /// shown disabled.
  final ValueChanged<StoredScanModel>? onRemove;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    if (scans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'أكبر الملفات',
          style: AppTextStyles.font16MediumText.copyWith(color: glass.onGlass),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final scan in scans)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: glass.surfaceGradient,
              borderRadius: BorderRadius.circular(AppRadius.glass),
              border: Border.all(color: glass.strokeColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scan.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font14MediumText.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                      Text(
                        [
                          scan.sizeLabel,
                          if (scan.caseNumber != null) 'طلب ${scan.caseNumber}',
                          if (scan.uploadedAt != null)
                            ApiTime.formatDate(scan.uploadedAt!),
                        ].join(' · '),
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Flagged so a manual deletion is not spent on a file the
                // sweep was about to take anyway.
                if (scan.isEligibleForAutomaticRemoval)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.sm,
                    ),
                    child: Icon(
                      Icons.schedule,
                      size: 16,
                      color: glass.warning,
                    ),
                  ),
                if (onRemove != null)
                  IconButton(
                    tooltip: 'حذف الملف',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onRemove!(scan),
                    icon: Icon(Icons.delete_outline, color: glass.error),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentRemovals extends StatelessWidget {
  const _RecentRemovals({required this.removals});

  final List<RemovedScanModel> removals;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    if (removals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'آخر ما حُذف',
          style: AppTextStyles.font16MediumText.copyWith(color: glass.onGlass),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final removal in removals)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  // An archived scan can still be fetched off the NAS; one
                  // swept for age or budget is gone. Same row, different
                  // answer to "can I get it back".
                  removal.isArchived ? Icons.dns_outlined : Icons.delete_sweep,
                  size: 16,
                  color: removal.isArchived ? glass.info : glass.onGlassMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    removal.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ),
                Text(
                  [
                    removal.sizeLabel,
                    removal.removalReason?.label ?? '—',
                  ].join(' · '),
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.font12RegularHint.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlass,
            ),
          ),
        ],
      ),
    );
  }
}
