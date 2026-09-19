import 'package:dental_lab_app/features/users/data/models/user_model.dart';

/// One row of "who is scoped to which doctors"
/// (`UserDoctorScopeSummaryDto`).
///
/// **An empty [doctorIds] means unrestricted** — the absence of a restriction,
/// not a restriction to nothing. Getting that backwards would hide every
/// doctor from the people who can currently see them all.
class UserDoctorScopeSummaryModel {
  const UserDoctorScopeSummaryModel({
    required this.userId,
    this.username,
    this.displayName,
    this.type = UserType.employee,
    this.isAdmin = false,
    this.doctorIds = const [],
  });

  final String userId;
  final String? username;
  final String? displayName;
  final UserType type;

  /// Admin rows are listed for visibility but cannot be edited — an admin
  /// sees every doctor by design, and offering a scope editor for one would
  /// be offering a setting the server ignores.
  final bool isAdmin;

  final List<String> doctorIds;

  bool get isUnrestricted => doctorIds.isEmpty;

  /// Admins are unrestricted whatever the list says, so the row must not
  /// offer to narrow them.
  bool get isEditable => !isAdmin;

  String get label {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return username?.trim() ?? '—';
  }

  factory UserDoctorScopeSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserDoctorScopeSummaryModel(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      type: UserType.fromApi(json['type'] as int?),
      isAdmin: json['isAdmin'] as bool? ?? false,
      doctorIds: [
        for (final id in json['doctorIds'] as List<dynamic>? ?? const [])
          if (id is String) id,
      ],
    );
  }
}
