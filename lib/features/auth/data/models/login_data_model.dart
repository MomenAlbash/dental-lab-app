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
