/// The headline counters (`DashboardSummaryDto`).
class DashboardSummaryModel {
  const DashboardSummaryModel({
    this.totalCases = 0,
    this.totalDoctors = 0,
    this.totalClinics = 0,
    this.totalPatients = 0,
    this.totalLaboratories = 0,
  });

  final int totalCases;
  final int totalDoctors;
  final int totalClinics;
  final int totalPatients;

  /// Parsed but deliberately not shown: every request is scoped to one
  /// laboratory via the `X-Laboratory-Id` header, so a "laboratories" counter
  /// on this screen would either always read 1 or mean something other than
  /// what its name suggests. Kept off the UI until the API confirms which.
  final int totalLaboratories;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalCases: json['totalCases'] as int? ?? 0,
      totalDoctors: json['totalDoctors'] as int? ?? 0,
      totalClinics: json['totalClinics'] as int? ?? 0,
      totalPatients: json['totalPatients'] as int? ?? 0,
      totalLaboratories: json['totalLaboratories'] as int? ?? 0,
    );
  }
}
