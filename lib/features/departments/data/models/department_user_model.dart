/// One member of a department, identified by their **login**
/// (`ClinicDepartmentUserDto`).
///
/// This is the join that makes the two sides of a stage comparable: a stage
/// can name a department (a team) or name users directly, and this says which
/// people a department actually brings into that pool.
class DepartmentUserModel {
  const DepartmentUserModel({
    required this.userId,
    required this.employeeId,
    this.name,
    this.username,
    this.isSupervisor = false,
    this.isActive = true,
  });

  /// Who does the work. This is what a stage assignment stores.
  final String userId;

  /// The person behind the login — the roster, the attendance and the profile
  /// screens are all keyed on this. Here to link to their page, **never** to
  /// assign work.
  final String employeeId;

  final String? name;
  final String? username;

  /// Runs the team. Carried so a picker can offer "the supervisor" without a
  /// second call.
  final bool isSupervisor;

  /// A suspended login stays listed and is shown greyed rather than hidden:
  /// it is the explanation for why somebody the lab expects on a stage is not
  /// picking work up.
  final bool isActive;

  String get displayName {
    final full = name?.trim();
    if (full != null && full.isNotEmpty) return full;
    return username?.trim() ?? '—';
  }

  factory DepartmentUserModel.fromJson(Map<String, dynamic> json) {
    return DepartmentUserModel(
      userId: json['userId'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      name: json['name'] as String?,
      username: json['username'] as String?,
      isSupervisor: json['isSupervisor'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
