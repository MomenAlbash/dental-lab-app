/// One turnaround estimate, for one lab-declared priority level
/// (`PriorityDurationDto`).
///
/// One row per priority level the lab declared, not fixed columns — the
/// `low/normal/high/urgent` quartet this replaced belonged to the retired
/// `CasePriority` enum, so a lab with two rush tiers got four boxes and a lab
/// with six could only fill four of them.
///
/// Lives on the restoration **type** now, not on a stage of its route — see
/// `ClinicRestorationTypeDto.durations`. A route used to carry its own
/// per-stage estimates; the field was dropped from the stage DTO entirely.
class PriorityDurationModel {
  const PriorityDurationModel({
    required this.casePriorityId,
    this.priorityName,
    this.priorityNameAr,
    this.displayOrder = 0,
    this.durationMinutes = 0,
  });

  final String casePriorityId;
  final String? priorityName;
  final String? priorityNameAr;
  final int displayOrder;

  /// The whole turnaround, in minutes.
  final int durationMinutes;

  String get priorityLabel {
    final ar = priorityNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return priorityName?.trim() ?? '';
  }

  factory PriorityDurationModel.fromJson(Map<String, dynamic> json) {
    return PriorityDurationModel(
      casePriorityId: json['casePriorityId'] as String? ?? '',
      priorityName: json['priorityName'] as String?,
      priorityNameAr: json['priorityNameAr'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      durationMinutes: json['durationMinutes'] as int? ?? 0,
    );
  }
}
