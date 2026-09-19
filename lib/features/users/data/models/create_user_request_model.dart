/// Create payload for a user (`application/json`). Required: [type],
/// [username], [password]. The account is bound to either an employee
/// ([employeeId]) or a doctor ([doctorId]) depending on [type].
///
/// [isRepresentative] is a separate flag, not a third [type] value — the
/// server rejects `type: 2` ("unsupported user type") even though the
/// shared `UserType` schema enum lists a Representative member; that member
/// belongs to the Roles-permission-catalogue endpoints only.
class CreateUserRequestModel {
  final int type;
  final String username;
  final String password;
  final String? email;
  final bool isAdmin;
  final bool isRepresentative;
  final String? roleId;
  final String? employeeId;
  final String? doctorId;

  CreateUserRequestModel({
    required this.type,
    required this.username,
    required this.password,
    this.email,
    this.isAdmin = false,
    this.isRepresentative = false,
    this.roleId,
    this.employeeId,
    this.doctorId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'username': username,
      'password': password,
      'email': email,
      'isAdmin': isAdmin,
      'isRepresentative': isRepresentative,
      'roleId': roleId,
      'employeeId': employeeId,
      'doctorId': doctorId,
    };
  }
}
