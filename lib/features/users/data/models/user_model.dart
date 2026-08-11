import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/roles/data/models/role_model.dart';

/// Whether the account is bound to an employee or a doctor record. Encoded by
/// the API as `0` / `1` (`UserType`). The names are undocumented, so the
/// mapping is kept here as the single source of truth.
enum UserType {
  employee, // 0
  doctor; // 1

  int get apiValue => index;

  bool get isDoctor => this == UserType.doctor;

  static UserType fromApi(int? value) =>
      value == 1 ? UserType.doctor : UserType.employee;
}

/*
{
  "id": "...",
  "username": "laila.admin",
  "email": "laila@example.com",
  "isActive": true,
  "isAdmin": true,
  "type": 0,
  "roleId": "...",
  "role": { ... },
  "employeeId": "...",
  "employee": { ... },
  "doctorId": null,
  "doctor": null
}
 */

class UserModel {
  final String id;
  final String? username;
  final String? email;
  final bool isActive;
  final bool isAdmin;
  final UserType type;
  final String? roleId;
  final RoleModel? role;
  final String? employeeId;
  final EmployeeModel? employee;
  final String? doctorId;
  final DoctorModel? doctor;

  UserModel({
    required this.id,
    this.username,
    this.email,
    this.isActive = true,
    this.isAdmin = false,
    this.type = UserType.employee,
    this.roleId,
    this.role,
    this.employeeId,
    this.employee,
    this.doctorId,
    this.doctor,
  });

  String? get roleName => role?.name;

  /// Name of the linked employee/doctor record, depending on [type].
  String get linkedName =>
      type.isDoctor ? (doctor?.fullName ?? '') : (employee?.fullName ?? '');

  /// Photo of the linked employee/doctor record, depending on [type]. A user
  /// account has no photo of its own — it borrows the one from whichever
  /// record it's bound to.
  String? get imagePath =>
      type.isDoctor ? doctor?.imagePath : employee?.imagePath;

  /// Up to two leading characters of [linkedName], used as the avatar
  /// fallback when there is no photo.
  String get initials {
    final name = linkedName.trim();
    if (name.isEmpty) {
      final u = username?.trim() ?? '';
      return u.isEmpty ? '؟' : u[0].toUpperCase();
    }
    final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    // `runes.first` rather than `part[0]`: indexing returns a UTF-16 code
    // unit, which would split a surrogate pair.
    return parts
        .map((part) => String.fromCharCode(part.runes.first))
        .take(2)
        .join();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String?,
      email: json['email'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isAdmin: json['isAdmin'] as bool? ?? false,
      type: UserType.fromApi(json['type'] as int?),
      roleId: json['roleId'] as String?,
      role: json['role'] == null
          ? null
          : RoleModel.fromJson(json['role'] as Map<String, dynamic>),
      employeeId: json['employeeId'] as String?,
      employee: json['employee'] == null
          ? null
          : EmployeeModel.fromJson(json['employee'] as Map<String, dynamic>),
      doctorId: json['doctorId'] as String?,
      doctor: json['doctor'] == null
          ? null
          : DoctorModel.fromJson(json['doctor'] as Map<String, dynamic>),
    );
  }
}
