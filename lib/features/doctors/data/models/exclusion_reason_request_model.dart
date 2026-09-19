/// Body of `PUT /doctors/{doctorId}/excluded-representatives/{userId}`
/// (`ExclusionReasonRequest`).
///
/// [reason] is read by whoever later wonders why a whole zone's
/// representative never appears for one doctor — worth writing, never
/// required.
class ExclusionReasonRequestModel {
  const ExclusionReasonRequestModel({this.reason});

  final String? reason;

  Map<String, dynamic> toJson() => {
    if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
  };
}
