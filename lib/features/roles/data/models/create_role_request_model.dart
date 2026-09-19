import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/features/roles/data/models/role_model.dart';

/// `ClinicCreateRoleRequest`. `userType` is always [RoleUserType.employee] here —
/// this screen only ever creates roles for the clinic's own staff.
class CreateRoleRequestModel {
  const CreateRoleRequestModel({
    required this.name,
    this.description,
    this.permissions = const [],
  });

  final String name;
  final String? description;
  final List<RolePermission> permissions;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'userType': RoleUserType.employee.value,
    'permissions': permissions.map((p) => p.toJson()).toList(),
  };
}
