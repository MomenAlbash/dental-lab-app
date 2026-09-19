import 'dart:developer';

import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/departments/data/models/department_user_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/users/data/models/user_doctor_scope_model.dart';
import 'package:dio/dio.dart';

List<T> _decodeList<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (data is! List) return const [];
  return [
    for (final entry in data)
      if (entry is Map<String, dynamic>) fromJson(entry),
  ];
}

/// Photos, employment status, notes and doctor scope.
///
/// A second extension beside [AttendanceApi], for the same reason: these are
/// the endpoints the people screens reach for, and folding them into the one
/// service file that already carries every other feature would not make them
/// easier to find.
extension PeopleApi on ApiService {
  // ---- Photos -----------------------------------------------------------
  //
  // Every one of these is multipart with the id repeated in the body as well
  // as the path — that is how the API's binder is written, and sending only
  // one of the two is a 400 that reads like a file problem.

  Future<FormData> _imageForm(String id, String filePath) async => FormData.fromMap({
    'Id': id,
    'file': await MultipartFile.fromFile(filePath),
  });

  /// `POST /Doctors/{id}/image`
  Future<DoctorModel> uploadDoctorImage({
    required String id,
    required String filePath,
    String? token,
  }) async {
    log('Uploading image for doctor: $id');

    final response = await Api().post(
      url: 'Doctors/$id/image',
      body: await _imageForm(id, filePath),
      isFormData: true,
      token: token,
    );
    return DoctorModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /Employees/{id}/image`
  Future<EmployeeModel> uploadEmployeeImage({
    required String id,
    required String filePath,
    String? token,
  }) async {
    log('Uploading image for employee: $id');

    final response = await Api().post(
      url: 'Employees/$id/image',
      body: await _imageForm(id, filePath),
      isFormData: true,
      token: token,
    );
    return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /Clinics/{id}/image`
  ///
  /// Returns the raw map rather than a model: the clinics feature owns that
  /// shape, and this transport has no business deciding which of its two
  /// representations a caller wanted.
  Future<Map<String, dynamic>> uploadClinicImage({
    required String id,
    required String filePath,
    String? token,
  }) async {
    log('Uploading image for clinic: $id');

    final response = await Api().post(
      url: 'Clinics/$id/image',
      body: await _imageForm(id, filePath),
      isFormData: true,
      token: token,
    );
    return response.data as Map<String, dynamic>;
  }

  /// `POST /RestorationTypes/{id}/website-image`
  ///
  /// The public website's picture of this product — not the stage artwork the
  /// bench sees, which is [uploadRestorationStageImage].
  Future<Map<String, dynamic>> uploadRestorationTypeWebsiteImage({
    required String id,
    required String filePath,
    String? token,
  }) async {
    log('Uploading website image for restoration type: $id');

    // The only one of these that takes the file alone — no repeated id.
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await Api().post(
      url: 'RestorationTypes/$id/website-image',
      body: formData,
      isFormData: true,
      token: token,
    );
    return response.data as Map<String, dynamic>;
  }

  /// `POST /restoration-type-stages/{id}/image` — the backdrop a stage shows
  /// on the bench.
  Future<Map<String, dynamic>> uploadRestorationStageImage({
    required String id,
    required String filePath,
    String? token,
  }) async {
    log('Uploading image for restoration stage: $id');

    final response = await Api().post(
      url: 'restoration-type-stages/$id/image',
      body: await _imageForm(id, filePath),
      isFormData: true,
      token: token,
    );
    return response.data as Map<String, dynamic>;
  }

  // ---- Employment status ------------------------------------------------

  /// `POST /Employees/{id}/terminate`
  ///
  /// Ends the employment, dated. The employee is **not** deleted: their
  /// attendance, payslips and case history are all still real, and removing
  /// the person would orphan every one of them.
  Future<EmployeeModel> terminateEmployee({
    required String id,
    required DateTime terminationDate,
    String? note,
    String? token,
  }) async {
    log('Terminating employee: $id');

    final response = await Api().post(
      url: 'Employees/$id/terminate',
      body: {
        'terminationDate': ApiTime.formatDate(terminationDate),
        'note': ?note,
      },
      token: token,
    );
    return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /Employees/{id}/reinstate` — somebody came back.
  Future<EmployeeModel> reinstateEmployee({
    required String id,
    String? token,
  }) async {
    log('Reinstating employee: $id');

    final response = await Api().post(
      url: 'Employees/$id/reinstate',
      body: const <String, dynamic>{},
      token: token,
    );
    return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---- Employee notes ---------------------------------------------------

  /// `GET /Employees/notes` — every note, or one employee's.
  Future<List<EmployeeNoteModel>> getEmployeeNotes({
    String? employeeId,
    String? token,
  }) async {
    log('Fetching employee notes');

    final data = await Api().get(
      url: employeeId == null
          ? 'Employees/notes'
          : 'Employees/notes?employeeId=${Uri.encodeQueryComponent(employeeId)}',
      token: token,
    );
    return _decodeList(data, EmployeeNoteModel.fromJson);
  }

  /// `POST /Employees/notes`
  Future<EmployeeNoteModel> createEmployeeNote({
    required String employeeId,
    required String note,
    String? token,
  }) async {
    log('Adding a note for employee: $employeeId');

    final response = await Api().post(
      url: 'Employees/notes',
      body: {'employeeId': employeeId, 'note': note},
      token: token,
    );
    return EmployeeNoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /Employees/notes/{noteId}`
  Future<void> deleteEmployeeNote({
    required String noteId,
    String? token,
  }) async {
    log('Deleting employee note: $noteId');

    await Api().delete(url: 'Employees/notes/$noteId', token: token);
  }

  // ---- Doctor scope -----------------------------------------------------

  /// `GET /Users/{id}/doctor-scope` — the doctor ids this login is restricted
  /// to.
  ///
  /// **Empty means unrestricted**, not "no doctors" — the absence of a
  /// restriction rather than a restriction to nothing.
  Future<List<String>> getUserDoctorScope({
    required String userId,
    String? token,
  }) async {
    log('Fetching doctor scope for user: $userId');

    final data = await Api().get(
      url: 'Users/$userId/doctor-scope',
      token: token,
    );
    if (data is! List) return const [];
    return [
      for (final id in data)
        if (id is String) id,
    ];
  }

  /// `PUT /Users/{id}/doctor-scope` — the complete set, not a delta.
  ///
  /// Sending an empty list lifts the restriction entirely, which is the only
  /// way to put a user back to seeing every doctor.
  Future<void> setUserDoctorScope({
    required String userId,
    required List<String> doctorIds,
    String? token,
  }) async {
    log('Setting doctor scope for user $userId: ${doctorIds.length} doctors');

    await Api().put(
      url: 'Users/$userId/doctor-scope',
      body: doctorIds,
      token: token,
    );
  }

  /// `GET /Users/doctor-scope-summary` — who is scoped to whom, across the lab.
  Future<List<UserDoctorScopeSummaryModel>> getDoctorScopeSummary({
    String? token,
  }) async {
    log('Fetching doctor scope summary');

    final data = await Api().get(
      url: 'Users/doctor-scope-summary',
      token: token,
    );
    return _decodeList(data, UserDoctorScopeSummaryModel.fromJson);
  }

  // ---- Department staffing ---------------------------------------------

  /// `GET /Departments/{id}/users` — the people a department brings into a
  /// stage's pool.
  Future<List<DepartmentUserModel>> getDepartmentUsers({
    required String departmentId,
    String? token,
  }) async {
    log('Fetching users of department: $departmentId');

    final data = await Api().get(
      url: 'Departments/$departmentId/users',
      token: token,
    );
    return _decodeList(data, DepartmentUserModel.fromJson);
  }
}
