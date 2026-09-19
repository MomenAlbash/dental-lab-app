import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:flutter/material.dart';

/// Picks which restoration stages a department owns.
///
/// Grouped by restoration type because a bare stage name does not identify a
/// stage: a lab that finishes both crowns and dentures has two "التشطيب", and
/// they are different rows on different routes. The type is the only thing
/// that tells them apart.
///
/// Returns the full selection, or null if the sheet was dismissed — the save
/// request replaces the membership wholesale, so a partial answer would read
/// as "unlink the rest".
Future<Set<String>?> showDepartmentStagesPicker(
  BuildContext context, {
  required List<RestorationTypeModel> types,
  required Set<String> selectedIds,
  Map<String, String> ownerByStageId = const {},
}) {
  return showGlassBottomSheet<Set<String>>(
    context: context,
    builder: (_) => _StagesPicker(
      types: types,
      selectedIds: selectedIds,
      ownerByStageId: ownerByStageId,
    ),
  );
}

class _StagesPicker extends StatefulWidget {
  const _StagesPicker({
    required this.types,
    required this.selectedIds,
    required this.ownerByStageId,
  });

  final List<RestorationTypeModel> types;
  final Set<String> selectedIds;

  /// Stage id → another department that also works it, excluding this one.
  ///
  /// Shown, **not** enforced: the server keeps these on a `WorkflowStage`
  /// ↔ `WorkflowStageDepartment` join table, so a stage may be shared by
  /// several departments. Saying so is useful; blocking it would forbid a
  /// split the lab is entitled to make.
  final Map<String, String> ownerByStageId;

  @override
  State<_StagesPicker> createState() => _StagesPickerState();
}

class _StagesPickerState extends State<_StagesPicker> {
  late final Set<String> _selected = {...widget.selectedIds};
  late final TextEditingController _searchController = TextEditingController()
    ..addListener(() => setState(() => _query = _searchController.text.trim()));

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(RestorationTypeModel type, CaseWorkflowStageModel stage) {
    if (_query.isEmpty) return true;
    // Matching the type name too means "كل مراحل الجسور" is one search, not a
    // hunt through a list whose stage names say nothing about the type.
    return stage.displayName.contains(_query) ||
        type.displayName.contains(_query);
  }

  /// Types that still have something to show, each with its surviving stages.
  List<(RestorationTypeModel, List<CaseWorkflowStageModel>)> get _groups => [
    for (final type in widget.types)
      if ([
            for (final stage in type.stages)
              if (stage.isActive && _matches(type, stage)) stage,
          ]
          case final stages when stages.isNotEmpty)
        (type, stages),
  ];

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final groups = _groups;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.cardPadding,
              AppSpacing.cardPadding,
              AppSpacing.cardPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'مراحل التعويضات التي يعمل عليها القسم',
                  style: AppTextStyles.font18MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'المرحلة المرتبطة بقسم تُسنَد إلى موظفيه.',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextFormField(
                  controller: _searchController,
                  hintText: 'ابحث باسم المرحلة أو التعويض',
                  prefixIcon: Icon(Icons.search, color: glass.onGlassMuted),
                  validator: (_) => null,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          Flexible(
            child: groups.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Text(
                      _query.isEmpty
                          ? 'لا توجد مراحل تصنيع بعد. أضِفها من مسار التعويض أولاً.'
                          : 'لا نتائج',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.font14RegularSecondary.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.cardPadding,
                    ),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final (type, stages) = groups[index];
                      return _TypeGroup(
                        type: type,
                        stages: stages,
                        selected: _selected,
                        ownerByStageId: widget.ownerByStageId,
                        onToggle: (id) => setState(
                          () => _selected.contains(id)
                              ? _selected.remove(id)
                              : _selected.add(id),
                        ),
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: CustomButtonWidget(
              buttonText: 'تم (${_selected.length})',
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeGroup extends StatelessWidget {
  const _TypeGroup({
    required this.type,
    required this.stages,
    required this.selected,
    required this.ownerByStageId,
    required this.onToggle,
  });

  final RestorationTypeModel type;
  final List<CaseWorkflowStageModel> stages;
  final Set<String> selected;
  final Map<String, String> ownerByStageId;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 4),
          child: Text(
            type.displayName,
            style: AppTextStyles.font13MediumPrimary.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ),
        for (final stage in stages)
          Builder(
            builder: (context) {
              final owner = ownerByStageId[stage.id];

              return CheckboxListTile(
                value: selected.contains(stage.id),
                onChanged: (_) => onToggle(stage.id),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  stage.displayName.isEmpty ? 'بلا اسم' : stage.displayName,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                subtitle: switch (owner) {
                  // Information, not a block — a stage may be shared.
                  final name? => Text(
                    'يعمل عليها أيضاً قسم "$name"',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                  _ when stage.isCheckpoint => Text(
                    'مرحلة تدقيق — يمكن أن ترفض العمل',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.warning,
                    ),
                  ),
                  _ => null,
                },
              );
            },
          ),
      ],
    );
  }
}
