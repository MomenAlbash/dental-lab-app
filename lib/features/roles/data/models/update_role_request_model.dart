/// `ClinicUpdateRoleRequest` — name/description only. Permissions are a
/// separate call (`PUT /Roles/{id}/permissions`), not part of this request.
class UpdateRoleRequestModel {
  const UpdateRoleRequestModel({this.name, this.description});

  final String? name;
  final String? description;

  Map<String, dynamic> toJson() => {'name': name, 'description': description};
}
