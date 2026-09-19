import 'package:dental_lab_app/features/case_stages/data/models/case_stage_enums.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';

/// One heading in the workflow editor and the stages filed under it.
typedef CaseStageGroup = ({
  String title,
  String? note,
  List<CaseStageModel> stages,
});

/// Splits a running order into the two halves of the case's workflow.
///
/// This is what "بالتوازي مع الإنتاج / بعد الإنتاج" actually is: `CaseStageTiming` on
/// the stage row. `afterRestorations` is a barrier — the step it sits on does
/// not open until every restoration on the case has finished its own route —
/// so the split is a real rule the server enforces, not a display grouping.
///
/// A half with no stages is left out entirely rather than shown empty: a lab
/// that does everything before production should not be told it has an empty
/// second half.
List<CaseStageGroup> groupStagesByTiming(List<CaseStageModel> ordered) {
  final before = [
    for (final stage in ordered)
      if (stage.timing == CaseStageTiming.beforeRestorations) stage,
  ];
  final after = [
    for (final stage in ordered)
      if (stage.timing == CaseStageTiming.afterRestorations) stage,
  ];

  return [
    if (before.isNotEmpty)
      (
        title: CaseStageTiming.beforeRestorations.arabicLabel,
        note: null,
        stages: before,
      ),
    if (after.isNotEmpty)
      (
        title: CaseStageTiming.afterRestorations.arabicLabel,
        // Said on the heading because it is the one rule that makes a case
        // look stuck to someone who does not know about the barrier.
        note: 'لا تبدأ حتى تنتهي كل التعويضات',
        stages: after,
      ),
  ];
}
