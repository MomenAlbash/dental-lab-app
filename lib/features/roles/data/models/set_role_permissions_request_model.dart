import 'package:dental_lab_app/features/roles/data/models/role_model.dart';

/// `ClinicSetRolePermissionsRequest` — `PUT /Roles/{id}/permissions`.
class SetRolePermissionsRequestModel {
  const SetRolePermissionsRequestModel(this.permissions);

  final List<RolePermission> permissions;

  Map<String, dynamic> toJson() => {
    'permissions': permissions.map((p) => p.toJson()).toList(),
  };
}
