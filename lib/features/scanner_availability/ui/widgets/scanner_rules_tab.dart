import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_rule_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_rule_model.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_rules/scanner_rules_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_rules/scanner_rules_state.dart';
import 'package:dental_lab_app/features/scanner_availability/ui/widgets/scanner_rule_form_dialog.dart';
import 'package:dental_lab_app/features/scanner_availability/ui/widgets/scanner_rule_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The weekly windows the scanner takes appointments in.
class ScannerRulesTab extends StatefulWidget {
  const ScannerRulesTab({super.key});

  @override
  State<ScannerRulesTab> createState() => ScannerRulesTabState();
}

class ScannerRulesTabState extends State<ScannerRulesTab> {
  /// Last loaded rules, kept so a refetch after a save does not blank the list
  /// out behind the toast.
  List<ScannerAvailabilityRuleModel>? _lastRules;

  /// Called by the page's add button as well as the rows' edit action.
  Future<void> openForm({ScannerAvailabilityRuleModel? rule}) async {
    final cubit = context.read<ScannerRulesCubit>();

    final body = await showDialog<SaveScannerAvailabilityRuleRequestModel>(
      context: context,
      builder: (_) => ScannerRuleFormDialog(initialRule: rule),
    );
    if (body == null) return;

    await cubit.saveRule(id: rule?.id, body: body);
  }

  Future<void> _confirmDelete(ScannerAvailabilityRuleModel rule) async {
    final cubit = context.read<ScannerRulesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الموعد الأسبوعي',
      message:
          'سيتم إيقاف مواعيد ${rule.dayLabel} (${rule.timeRangeLabel}). متابعة؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) await cubit.deleteRule(rule.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScannerRulesCubit, ScannerRulesState>(
      // The save/delete outcomes are reported by the page's listener; rebuilding
      // on them would swap the list for a skeleton mid-toast.
      buildWhen: (previous, current) =>
          current is ScannerRulesInitial ||
          current is ScannerRulesLoading ||
          current is ScannerRulesLoaded ||
          current is ScannerRulesError,
      builder: (context, state) {
        if (state is ScannerRulesLoaded) _lastRules = state.rules;

        final rules = switch (state) {
          ScannerRulesLoaded(:final rules) => rules,
          ScannerRulesLoading() => _lastRules,
          _ => null,
        };

        return switch ((state, rules)) {
          (_, final List<ScannerAvailabilityRuleModel> loaded)
              when loaded.isEmpty =>
            const _Empty(),
          (_, final List<ScannerAvailabilityRuleModel> loaded) =>
            AdaptiveCollection<ScannerAvailabilityRuleModel>(
              items: loaded,
              onRefresh: context.read<ScannerRulesCubit>().getRules,
              itemBuilder: (context, rule, _) => ScannerRuleListItemWidget(
                rule: rule,
                onEdit: () => openForm(rule: rule),
                onDelete: () => _confirmDelete(rule),
              ),
            ),
          (ScannerRulesError(:final message), null) => Center(
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
          _ => const Padding(
            padding: EdgeInsets.only(top: 24),
            child: GlassListSkeleton(),
          ),
        };
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: glass.surfaceGradient,
                border: Border.all(color: glass.strokeColor),
              ),
              child: Icon(
                Icons.event_repeat_outlined,
                size: 40,
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'لا يوجد مواعيد أسبوعية',
              textAlign: TextAlign.center,
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              // Says what the consequence is, not just that the list is empty.
              'بدون مواعيد أسبوعية لن يتمكن الأطباء من حجز جلسة سكنر',
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
