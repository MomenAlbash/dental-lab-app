import 'package:dental_lab_app/core/auth/permissions.dart';

/// One `{ name, type }` grant, as the API reads and writes it —
/// `ClinicRolePermissionDto`.
class RolePermission {
  const RolePermission({required this.name, required this.type});

  final PermissionName name;
  final PermissionType type;

  /// Null for a `name`/`type` this build's enum does not know — dropped by
  /// the caller rather than guessed, same as `Permissions.fromUserJson`.
  static RolePermission? fromJson(Map<String, dynamic> json) {
    final name = PermissionName.fromValue(json['name'] as int?);
    final type = PermissionType.fromValue(json['type'] as int?);
    if (name == null || type == null) return null;
    return RolePermission(name: name, type: type);
  }

  Map<String, dynamic> toJson() => {'name': name.value, 'type': type.value};
}

/// `RoleDto`.
class RoleModel {
  final String id;
  final String? name;
  final String? description;
  final RoleUserType userType;
  final int userCount;
  final List<RolePermission> permissions;

  RoleModel({
    required this.id,
    this.name,
    this.description,
    this.userType = RoleUserType.employee,
    this.userCount = 0,
    this.permissions = const [],
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'] as List<dynamic>? ?? const [];

    return RoleModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      userType: RoleUserType.values.firstWhere(
        (t) => t.value == json['userType'] as int?,
        orElse: () => RoleUserType.employee,
      ),
      userCount: json['userCount'] as int? ?? 0,
      permissions: rawPermissions
          .whereType<Map<String, dynamic>>()
          .map(RolePermission.fromJson)
          .whereType<RolePermission>()
          .toList(),
    );
  }
}
