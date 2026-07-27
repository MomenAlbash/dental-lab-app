/// Update payload for a user (`application/json`). Editing is limited to
/// email, role, admin flag and active state — mirrors `UpdateUserRequest`.
class UpdateUserRequestModel {
  final String? email;
  final String? roleId;
  final String? laboratoryId;
  final bool? isAdmin;
  final bool? isActive;

  UpdateUserRequestModel({
    this.email,
    this.roleId,
    this.laboratoryId,
    this.isAdmin,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'roleId': roleId,
      'laboratoryId': laboratoryId,
      'isAdmin': isAdmin,
      'isActive': isActive,
    };
  }
}
