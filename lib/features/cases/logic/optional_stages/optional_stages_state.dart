/// One stage the case may opt into, flattened from wherever it was defined.
class OptionalStage {
  const OptionalStage({
    required this.id,
    required this.name,
    required this.isCaseStage,
    this.restorationTypeIds = const {},
  });

  final String id;
  final String name;

  /// Which of the two catalogues declared it — and therefore which field
  /// carries its answer on the wire.
  ///
  /// The API keeps them apart: a case's own optional stages go out as the
  /// request's `selectedCaseStagesIds`, while a restoration route's go on the
  /// restoration that runs them, as `restorationTypeStageIds`. Sending a
  /// route stage at case level is silently dropped, which is exactly the kind
  /// of bug nobody notices until a case runs without a stage somebody asked
  /// for.
  final bool isCaseStage;

  /// The restoration types whose route offers this stage. Empty for a case
  /// stage, which belongs to no type.
  ///
  /// Kept per-type rather than collapsed to a flag because the answer has to
  /// land on the right restorations: a case with a crown and a denture that
  /// both offer "glazing" sends it on both, and one that offers it on only
  /// the crown sends it on the crown alone.
  final Set<String> restorationTypeIds;

  /// Where it comes from, in words — shown beside the question so "هل تريد
  /// التجربة؟" is answerable.
  String get source => isCaseStage ? 'مراحل الحالة' : 'مسار التعويض';
}

class OptionalStagesState {
  const OptionalStagesState({
    this.stages = const [],
    this.isLoading = false,
    this.hasLoaded = false,
    this.hasFailure = false,
  });

  final List<OptionalStage> stages;
  final bool isLoading;

  /// True once an answer arrived, so an empty list reads as "there are none"
  /// rather than "not asked yet".
  final bool hasLoaded;

  /// At least one source could not be read. The list may be short; the form
  /// says so rather than implying the lab has no optional stages.
  final bool hasFailure;

  bool get isEmpty => hasLoaded && stages.isEmpty;

  /// Whether every stage on offer has an explicit yes/no in [answers].
  ///
  /// The form refuses to submit until this is true: a stage nobody answered
  /// is not the same as one answered "no", and letting an unanswered question
  /// pass as a refusal decides on the user's behalf.
  bool allAnswered(Map<String, bool> answers) =>
      stages.every((stage) => answers.containsKey(stage.id));

  /// The stages still waiting on an answer, in the order they are asked —
  /// so the form can name the first one instead of saying "something is
  /// missing".
  List<OptionalStage> unanswered(Map<String, bool> answers) => [
    for (final stage in stages)
      if (!answers.containsKey(stage.id)) stage,
  ];

  /// The case-level stages answered "yes" — the request's
  /// `selectedCaseStagesIds`.
  List<String> selectedCaseStageIds(Map<String, bool> answers) => [
    for (final stage in stages)
      if (stage.isCaseStage && (answers[stage.id] ?? false)) stage.id,
  ];

  /// The route stages answered "yes" that [restorationTypeId] actually
  /// offers — one restoration's `restorationTypeStageIds`.
  List<String> selectedRouteStageIds(
    Map<String, bool> answers,
    String? restorationTypeId,
  ) {
    if (restorationTypeId == null || restorationTypeId.isEmpty) return const [];
    return [
      for (final stage in stages)
        if (!stage.isCaseStage &&
            stage.restorationTypeIds.contains(restorationTypeId) &&
            (answers[stage.id] ?? false))
          stage.id,
    ];
  }
}
