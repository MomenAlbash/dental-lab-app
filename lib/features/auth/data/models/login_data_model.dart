import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/features/auth/data/models/user_role_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';

/// The authenticated user returned inside the login response
/// (`ClinicUserDto`).
class LoginData {
  final String id;
  final String? username;
  final String? email;
  final bool isAdmin;
  final String? roleId;
  final UserRoleModel? role;
  final String? employeeId;
  final String? employeeFullName;
  final String? laboratoryId;
  final LaboratoryModel? laboratory;

  LoginData({
    required this.id,
    this.username,
    this.email,
    required this.isAdmin,
    this.roleId,
    this.role,
    this.employeeId,
    this.employeeFullName,
    this.laboratoryId,
    this.laboratory,
  });

  /// What this user may do, resolved from their role's grants plus [isAdmin].
  ///
  /// Lives here rather than in the cubit so there is exactly one place that
  /// knows how a `ClinicUserDto` turns into a [Permissions] — the login
  /// response and `GET /ClinicAuth/me` both return this shape.
  Permissions get permissions {
    final granted = <PermissionName, PermissionType>{};

    for (final entry in role?.permissions ?? const []) {
      final name = PermissionName.fromValue(entry.name);
      final type = PermissionType.fromValue(entry.type);
      if (name == null || type == null) continue;

      final existing = granted[name];
      if (existing == null || type.satisfies(existing)) {
        granted[name] = type;
      }
    }

    return Permissions(isAdmin: isAdmin, granted: granted);
  }

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      id: json['id'] as String,
      username: json['username'] as String?,
      email: json['email'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      roleId: json['roleId'] as String?,
      role: json['role'] != null
          ? UserRoleModel.fromJson(json['role'] as Map<String, dynamic>)
          : null,
      employeeId: json['employeeId'] as String?,
      employeeFullName: json['employeeFullName'] as String?,
      laboratoryId: json['laboratoryId'] as String?,
      laboratory: json['laboratory'] != null
          ? LaboratoryModel.fromJson(json['laboratory'] as Map<String, dynamic>)
          : null,
    );
  }
}
