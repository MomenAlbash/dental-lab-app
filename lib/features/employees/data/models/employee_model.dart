import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_attachment_file_model.dart';

/// Gender as encoded by the API (`0` = male, `1` = female).
enum EmployeeGender {
  male,
  female;

  int get apiValue => index;

  String get arabicLabel => switch (this) {
    EmployeeGender.male => 'ذكر',
    EmployeeGender.female => 'أنثى',
  };

  static EmployeeGender? fromApi(int? value) => switch (value) {
    0 => EmployeeGender.male,
    1 => EmployeeGender.female,
    _ => null,
  };
}

/*
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "firstName": "ليلى",
  "lastName": "حمدان",
  "nationalNumber": "01234567890",
  "code": "EMP-001",
  "imagePath": null,
  "gender": 1,
  "dateOfBirth": "1995-03-12",
  "cityId": "...",
  "city": { "id": "...", "name": "دمشق" },
  "phoneNumber": "0991112233",
  "address": "المزة، دمشق",
  "bankName": "بنك سورية والمهجر",
  "bankAccountNumber": "123456789",
  "files": []
}
 */

class EmployeeModel {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? nationalNumber;
  final String? code;
  final String? imagePath;
  final EmployeeGender? gender;
  final String? dateOfBirth;
  final String? cityId;
  final CityModel? city;
  final String? phoneNumber;
  final String? address;
  final String? bankName;
  final String? bankAccountNumber;
  final List<EmployeeAttachmentFileModel> files;

  /// Still employed. False is a **terminated** employee, who stays listed
  /// rather than disappearing: their attendance, payslips and case history
  /// are all still real, and hiding the person would orphan every one of them.
  final bool isActive;

  /// A field representative — the pool scanner sessions are assigned from.
  /// Only a flagged employee can be put on a zone.
  final bool isRepresentative;

  /// When they came off probation.
  final DateTime? stabilizationDate;

  /// Null while they are still employed; set once terminated, which is what
  /// [isActive] reflects.
  final DateTime? terminationDate;

  /// The linked login, when there is one.
  final String? userId;
  final String? username;

  /// Whether that login may sign in. **Null means there is no login at all** —
  /// a different thing from a login that exists but is suspended, and the two
  /// are shown differently.
  final bool? userIsActive;

  final String? userRoleName;
  final bool userIsAdmin;

  EmployeeModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.nationalNumber,
    this.code,
    this.imagePath,
    this.gender,
    this.dateOfBirth,
    this.cityId,
    this.city,
    this.phoneNumber,
    this.address,
    this.bankName,
    this.bankAccountNumber,
    this.files = const [],
    this.isActive = true,
    this.isRepresentative = false,
    this.stabilizationDate,
    this.terminationDate,
    this.userId,
    this.username,
    this.userIsActive,
    this.userRoleName,
    this.userIsAdmin = false,
  });

  /// Whether this employee has a login at all — distinct from having one that
  /// is currently suspended.
  bool get hasLogin => userId != null;

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  /// Up to two leading characters of the name, used as the avatar fallback
  /// when there is no photo.
  String get initials {
    final parts = [firstName, lastName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '؟';
    // `runes.first` rather than `part[0]`: indexing returns a UTF-16 code
    // unit, which would split a surrogate pair.
    return parts
        .map((part) => String.fromCharCode(part.runes.first))
        .take(2)
        .join();
  }

  String? get cityName => city?.name;

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      nationalNumber: json['nationalNumber'] as String?,
      code: json['code'] as String?,
      imagePath: json['imagePath'] as String?,
      gender: EmployeeGender.fromApi(json['gender'] as int?),
      dateOfBirth: json['dateOfBirth'] as String?,
      cityId: json['cityId'] as String?,
      city: json['city'] == null
          ? null
          : CityModel.fromJson(json['city'] as Map<String, dynamic>),
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      bankName: json['bankName'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      files:
          (json['files'] as List<dynamic>?)
              ?.map(
                (e) => EmployeeAttachmentFileModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      isActive: json['isActive'] as bool? ?? true,
      isRepresentative: json['isRepresentative'] as bool? ?? false,
      stabilizationDate: DateTime.tryParse(
        json['stabilizationDate'] as String? ?? '',
      ),
      terminationDate: DateTime.tryParse(
        json['terminationDate'] as String? ?? '',
      ),
      userId: json['userId'] as String?,
      username: json['username'] as String?,
      userIsActive: json['userIsActive'] as bool?,
      userRoleName: json['userRoleName'] as String?,
      userIsAdmin: json['userIsAdmin'] as bool? ?? false,
    );
  }
}

/// One note somebody left on an employee's file (`EmployeeNoteDto`).
///
/// Append-only in practice: a note carries who wrote it and when, and the way
/// to correct one is another note rather than an edit — which is why there is
/// no update endpoint for it.
class EmployeeNoteModel {
  const EmployeeNoteModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.authorId,
    this.authorName,
    this.note,
    this.createdAt,
  });

  final String id;
  final String employeeId;
  final String? employeeName;
  final String? authorId;
  final String? authorName;
  final String? note;
  final DateTime? createdAt;

  factory EmployeeNoteModel.fromJson(Map<String, dynamic> json) {
    return EmployeeNoteModel(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String?,
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
