import 'package:dental_lab_app/features/users/data/models/user_model.dart';

/// Filters applied to the users list (`GET /api/clinic/Users` query params).
/// All fields are optional — `null` means "don't filter by this".
///
/// A user is bound to either a doctor or an employee record ([UserType]), so
/// [doctorId] and [employeeId] are mutually exclusive in practice: the filter
/// sheet only ever sets one of them, based on which linked-record type is
/// selected. Both are kept so a previously picked doctor/employee survives a
/// type switch back and forth without being lost.
class UserFiltersModel {
  const UserFiltersModel({
    this.laboratoryId,
    this.laboratoryName,
    this.type,
    this.doctorId,
    this.doctorName,
    this.employeeId,
    this.employeeName,
  });

  static const empty = UserFiltersModel();

  final String? laboratoryId;
  final String? laboratoryName;

  /// Which linked-record picker the sheet shows. Not itself sent to the
  /// API — only whichever of [doctorId] / [employeeId] it resolves to is.
  final UserType? type;

  final String? doctorId;
  final String? doctorName;
  final String? employeeId;
  final String? employeeName;

  /// The id actually sent to the API for the linked-record filter, per
  /// [type]. Null if no type is selected or the corresponding picker is
  /// still empty.
  String? get linkedId => switch (type) {
    UserType.doctor => doctorId,
    UserType.employee => employeeId,
    null => null,
  };

  bool get isEmpty => laboratoryId == null && linkedId == null;

  int get activeCount =>
      [laboratoryId, linkedId].where((v) => v != null).length;

  UserFiltersModel copyWith({
    String? laboratoryId,
    String? laboratoryName,
    bool clearLaboratory = false,
    UserType? type,
    bool clearType = false,
    String? doctorId,
    String? doctorName,
    bool clearDoctor = false,
    String? employeeId,
    String? employeeName,
    bool clearEmployee = false,
  }) {
    return UserFiltersModel(
      laboratoryId: clearLaboratory
          ? null
          : (laboratoryId ?? this.laboratoryId),
      laboratoryName: clearLaboratory
          ? null
          : (laboratoryName ?? this.laboratoryName),
      type: clearType ? null : (type ?? this.type),
      doctorId: clearDoctor ? null : (doctorId ?? this.doctorId),
      doctorName: clearDoctor ? null : (doctorName ?? this.doctorName),
      employeeId: clearEmployee ? null : (employeeId ?? this.employeeId),
      employeeName: clearEmployee ? null : (employeeName ?? this.employeeName),
    );
  }
}
