/// One priority level's turnaround estimate, for
/// `SaveRestorationTypeRequest.durations` (`SavePriorityDurationRequest`).
///
/// Shaped like the storage columns — whole days plus an hours-and-minutes
/// remainder — rather than one combined minute count: a lab entering "3 days,
/// 4 hours" sends [durationDays] 3 and [durationMinutes] 240. A combined
/// total was tried and reverted server-side because neither side could tell
/// "3 days" from a typo'd total once it was one number.
///
/// A level omitted from the list has its estimate cleared, so a form must
/// send every row it wants to keep, not only the ones that changed.
class SavePriorityDurationRequestModel {
  const SavePriorityDurationRequestModel({
    required this.casePriorityId,
    required this.durationDays,
    required this.durationMinutes,
  });

  /// Splits a plain total into the day/remainder shape the API stores. The
  /// form asks for one number — the total is easier to reason about than two
  /// boxes — and this is where it is converted.
  factory SavePriorityDurationRequestModel.fromTotalMinutes({
    required String casePriorityId,
    required int totalMinutes,
  }) => SavePriorityDurationRequestModel(
    casePriorityId: casePriorityId,
    durationDays: totalMinutes ~/ 1440,
    durationMinutes: totalMinutes % 1440,
  );

  final String casePriorityId;

  /// Whole days of the turnaround.
  final int durationDays;

  /// The hours-and-minutes remainder within the last day — NOT the whole
  /// turnaround.
  final int durationMinutes;

  Map<String, dynamic> toJson() => {
    'casePriorityId': casePriorityId,
    'durationDays': durationDays,
    'durationMinutes': durationMinutes,
  };
}
