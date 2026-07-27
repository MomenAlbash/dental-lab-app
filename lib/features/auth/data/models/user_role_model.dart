/// A single permission granted to a role. `name` and `type` are raw integer
/// enum codes (`PermissionName` / `PermissionType`) — the API doesn't publish
/// string labels for them yet.
class RolePermissionModel {
  final int? name;
  final int? type;

  RolePermissionModel({this.name, this.type});

  factory RolePermissionModel.fromJson(Map<String, dynamic> json) {
    return RolePermissionModel(
      name: json['name'] as int?,
      type: json['type'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'type': type};
  }
}

class UserRoleModel {
  final String id;
  final String? name;
  final String? description;
  final int userCount;
  final List<RolePermissionModel>? permissions;

  UserRoleModel({
    required this.id,
    this.name,
    this.description,
    required this.userCount,
    this.permissions,
  });

  factory UserRoleModel.fromJson(Map<String, dynamic> json) {
    return UserRoleModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      userCount: json['userCount'] as int? ?? 0,
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) => RolePermissionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
