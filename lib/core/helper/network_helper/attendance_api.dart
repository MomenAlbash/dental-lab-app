import 'dart:developer';

import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/attendance/data/models/daily_attendance_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/employee_work_system_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/fingerprint_device_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/leave_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/punch_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/work_shift_model.dart';
import 'package:dental_lab_app/features/payroll/data/models/payroll_enums.dart';
import 'package:dental_lab_app/features/payroll/data/models/salary_model.dart';

/// Decodes a JSON array, tolerating a null body.
///
/// A local copy of [ApiService]'s own list decoder: an extension cannot reach
/// a private member of another library, and one four-line helper is a smaller
/// cost than making that one public for this.
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

String _query(List<MapEntry<String, String?>> params) {
  final parts = [
    for (final entry in params)
      if (entry.value != null && entry.value!.isNotEmpty)
        '${entry.key}=${Uri.encodeQueryComponent(entry.value!)}',
  ];
  return parts.isEmpty ? '' : '?${parts.join('&')}';
}

String? _date(DateTime? value) =>
    value == null ? null : ApiTime.formatDate(value);

/// Attendance and payroll transport.
///
/// An extension rather than more of [ApiService] itself: this module is some
/// fifty endpoints across eight controllers, and folding them into a file that
/// already carries every other feature would make the one nobody can navigate.
/// Callers still reach them through the same `getIt<ApiService>()` instance.
extension AttendanceApi on ApiService {
  // ---- Work shifts ------------------------------------------------------

  /// `GET /WorkShifts` — the laboratory's shift catalogue.
  Future<List<WorkShiftModel>> getWorkShifts({String? token}) async {
    log('Fetching work shifts');

    final data = await Api().get(url: 'WorkShifts', token: token);
    return _decodeList(data, WorkShiftModel.fromJson);
  }

  /// `GET /WorkShifts/{id}`
  Future<WorkShiftModel> getWorkShiftById({
    required String id,
    String? token,
  }) async {
    log('Fetching work shift: $id');

    final data = await Api().get(url: 'WorkShifts/$id', token: token);
    return WorkShiftModel.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /WorkShifts`
  Future<WorkShiftModel> createWorkShift({
    required SaveWorkShiftRequestModel body,
    String? token,
  }) async {
    log('Creating work shift: ${body.name}');

    final response = await Api().post(
      url: 'WorkShifts',
      body: body.toJson(),
      token: token,
    );
    return WorkShiftModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PUT /WorkShifts/{id}`
  Future<WorkShiftModel> updateWorkShift({
    required String id,
    required SaveWorkShiftRequestModel body,
    String? token,
  }) async {
    log('Updating work shift: $id');

    final response = await Api().put(
      url: 'WorkShifts/$id',
      body: body.toJson(),
      token: token,
    );
    return WorkShiftModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /WorkShifts/{id}`
  Future<void> deleteWorkShift({required String id, String? token}) async {
    log('Deleting work shift: $id');

    await Api().delete(url: 'WorkShifts/$id', token: token);
  }

  /// `GET /WorkShifts/{id}/attendance-impact` — read **before** saving an edit.
  ///
  /// The days already judged against the shift's old rules, and who worked
  /// them: the editor warns first, then knows exactly what range to recompute.
  Future<WorkShiftAttendanceImpactModel> getWorkShiftAttendanceImpact({
    required String id,
    String? token,
  }) async {
    log('Fetching attendance impact for work shift: $id');

    final data = await Api().get(
      url: 'WorkShifts/$id/attendance-impact',
      token: token,
    );
    return WorkShiftAttendanceImpactModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  // ---- Employee → shift spells -----------------------------------------

  /// `GET /employee-work-systems/employee/{id}` — the whole history.
  Future<List<EmployeeWorkSystemModel>> getEmployeeWorkSystems({
    required String employeeId,
    String? token,
  }) async {
    log('Fetching work system history for employee: $employeeId');

    final data = await Api().get(
      url: 'employee-work-systems/employee/$employeeId',
      token: token,
    );
    return _decodeList(data, EmployeeWorkSystemModel.fromJson);
  }

  /// `GET /employee-work-systems/employee/{id}/active`
  Future<EmployeeWorkSystemModel?> getActiveEmployeeWorkSystem({
    required String employeeId,
    String? token,
  }) async {
    log('Fetching active work system for employee: $employeeId');

    final data = await Api().get(
      url: 'employee-work-systems/employee/$employeeId/active',
      token: token,
    );
    // An employee on no shift at all is an ordinary answer, not an error.
    if (data is! Map<String, dynamic>) return null;
    return EmployeeWorkSystemModel.fromJson(data);
  }

  /// `GET /employee-work-systems/active?employeeIds=` — several at once.
  Future<List<EmployeeWorkSystemModel>> getActiveWorkSystems({
    required List<String> employeeIds,
    String? token,
  }) async {
    log('Fetching active work systems for ${employeeIds.length} employees');

    final query = employeeIds
        .map((id) => 'employeeIds=${Uri.encodeQueryComponent(id)}')
        .join('&');

    final data = await Api().get(
      url: 'employee-work-systems/active${query.isEmpty ? '' : '?$query'}',
      token: token,
    );
    return _decodeList(data, EmployeeWorkSystemModel.fromJson);
  }

  /// `GET /employee-work-systems/shift/{id}` — who is on this shift now.
  Future<List<EmployeeWorkSystemModel>> getWorkShiftRoster({
    required String workShiftId,
    String? token,
  }) async {
    log('Fetching roster for work shift: $workShiftId');

    final data = await Api().get(
      url: 'employee-work-systems/shift/$workShiftId',
      token: token,
    );
    return _decodeList(data, EmployeeWorkSystemModel.fromJson);
  }

  /// `POST /employee-work-systems` — opens a new spell for one employee.
  Future<EmployeeWorkSystemModel> saveEmployeeWorkSystem({
    required SaveEmployeeWorkSystemRequestModel body,
    String? token,
  }) async {
    log('Saving work system for employee: ${body.employeeId}');

    final response = await Api().post(
      url: 'employee-work-systems',
      body: body.toJson(),
      token: token,
    );
    return EmployeeWorkSystemModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `POST /employee-work-systems/shift/assign` — several employees at once.
  Future<List<EmployeeWorkSystemModel>> assignWorkShiftEmployees({
    required AssignWorkShiftEmployeesRequestModel body,
    String? token,
  }) async {
    log('Assigning ${body.employeeIds.length} employees to a shift');

    final response = await Api().post(
      url: 'employee-work-systems/shift/assign',
      body: body.toJson(),
      token: token,
    );
    return _decodeList(response.data, EmployeeWorkSystemModel.fromJson);
  }

  // ---- Daily attendance -------------------------------------------------

  /// `GET /daily-attendance/employee/{id}` — one employee over a window.
  Future<List<DailyAttendanceModel>> getEmployeeAttendance({
    required String employeeId,
    DateTime? from,
    DateTime? to,
    String? token,
  }) async {
    log('Fetching attendance for employee: $employeeId');

    final data = await Api().get(
      url:
          'daily-attendance/employee/$employeeId'
          '${_query([MapEntry('from', _date(from)), MapEntry('to', _date(to))])}',
      token: token,
    );
    return _decodeList(data, DailyAttendanceModel.fromJson);
  }

  /// `GET /daily-attendance/day` — everybody, on one day.
  Future<List<DailyAttendanceModel>> getAttendanceForDay({
    required DateTime date,
    String? token,
  }) async {
    log('Fetching attendance for day: ${ApiTime.formatDate(date)}');

    final data = await Api().get(
      url: 'daily-attendance/day${_query([MapEntry('date', _date(date))])}',
      token: token,
    );
    return _decodeList(data, DailyAttendanceModel.fromJson);
  }

  /// `GET /daily-attendance/range` — everybody, over a window.
  Future<List<DailyAttendanceModel>> getAttendanceForRange({
    required DateTime from,
    required DateTime to,
    String? token,
  }) async {
    log('Fetching attendance range');

    final data = await Api().get(
      url:
          'daily-attendance/range'
          '${_query([MapEntry('from', _date(from)), MapEntry('to', _date(to))])}',
      token: token,
    );
    return _decodeList(data, DailyAttendanceModel.fromJson);
  }

  /// `POST /daily-attendance/employee/{id}/recalculate`
  ///
  /// The read model does not update itself: a punch, a leave or a holiday
  /// changes what a day *should* say, and this is what makes it say it.
  Future<DailyAttendanceModel> recalculateAttendanceDay({
    required String employeeId,
    required DateTime date,
    String? token,
  }) async {
    log('Recalculating attendance for $employeeId on ${_date(date)}');

    final response = await Api().post(
      url:
          'daily-attendance/employee/$employeeId/recalculate'
          '${_query([MapEntry('date', _date(date))])}',
      body: const <String, dynamic>{},
      token: token,
    );
    return DailyAttendanceModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `POST /daily-attendance/employee/{id}/recalculate-range` — returns how
  /// many days were recomputed.
  Future<int> recalculateAttendanceRange({
    required String employeeId,
    required DateTime from,
    required DateTime to,
    String? token,
  }) async {
    log('Recalculating attendance range for $employeeId');

    final response = await Api().post(
      url:
          'daily-attendance/employee/$employeeId/recalculate-range'
          '${_query([MapEntry('from', _date(from)), MapEntry('to', _date(to))])}',
      body: const <String, dynamic>{},
      token: token,
    );
    return (response.data as num?)?.toInt() ?? 0;
  }

  // ---- Punches ----------------------------------------------------------

  /// `GET /Punches/employee/{id}/day`
  Future<List<PunchModel>> getPunchesForDay({
    required String employeeId,
    required DateTime date,
    String? token,
  }) async {
    log('Fetching punches for $employeeId on ${_date(date)}');

    final data = await Api().get(
      url:
          'Punches/employee/$employeeId/day'
          '${_query([MapEntry('date', _date(date))])}',
      token: token,
    );
    return _decodeList(data, PunchModel.fromJson);
  }

  /// `POST /Punches/manual` — answers with the day as it now stands, so the
  /// caller never has to refetch to see the effect.
  Future<DailyAttendanceModel> addManualPunch({
    required AddManualPunchRequestModel body,
    String? token,
  }) async {
    log('Adding a manual punch for ${body.employeeId}');

    final response = await Api().post(
      url: 'Punches/manual',
      body: body.toJson(),
      token: token,
    );
    return DailyAttendanceModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `PUT /Punches/{id}` — moving a punch can move it onto another day, which
  /// is why the server recalculates both ends.
  Future<DailyAttendanceModel> updatePunch({
    required String id,
    required DateTime timestamp,
    String? token,
  }) async {
    log('Updating punch: $id');

    final response = await Api().put(
      url: 'Punches/$id',
      body: {'timestamp': timestamp.toIso8601String()},
      token: token,
    );
    return DailyAttendanceModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `DELETE /Punches/{id}`
  Future<DailyAttendanceModel?> deletePunch({
    required String id,
    String? token,
  }) async {
    log('Deleting punch: $id');

    final response = await Api().delete(url: 'Punches/$id', token: token);
    final data = response.data;
    if (data is! Map<String, dynamic>) return null;
    return DailyAttendanceModel.fromJson(data);
  }

  // ---- Fingerprint devices ---------------------------------------------

  /// `GET /fingerprint-devices`
  Future<List<FingerprintDeviceModel>> getFingerprintDevices({
    String? token,
  }) async {
    log('Fetching fingerprint devices');

    final data = await Api().get(url: 'fingerprint-devices', token: token);
    return _decodeList(data, FingerprintDeviceModel.fromJson);
  }

  /// `POST /fingerprint-devices`
  Future<FingerprintDeviceModel> createFingerprintDevice({
    required SaveFingerprintDeviceRequestModel body,
    String? token,
  }) async {
    log('Registering fingerprint device: ${body.name}');

    final response = await Api().post(
      url: 'fingerprint-devices',
      body: body.toJson(),
      token: token,
    );
    return FingerprintDeviceModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `PUT /fingerprint-devices/{id}`
  Future<FingerprintDeviceModel> updateFingerprintDevice({
    required String id,
    required SaveFingerprintDeviceRequestModel body,
    String? token,
  }) async {
    log('Updating fingerprint device: $id');

    final response = await Api().put(
      url: 'fingerprint-devices/$id',
      body: body.toJson(),
      token: token,
    );
    return FingerprintDeviceModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `DELETE /fingerprint-devices/{id}`
  Future<void> deleteFingerprintDevice({
    required String id,
    String? token,
  }) async {
    log('Deleting fingerprint device: $id');

    await Api().delete(url: 'fingerprint-devices/$id', token: token);
  }

  /// `GET /fingerprint-devices/employee-overview` — every employee and the
  /// codes they hold, including the ones holding none.
  Future<List<FingerprintOverviewModel>> getFingerprintOverview({
    String? token,
  }) async {
    log('Fetching fingerprint employee overview');

    final data = await Api().get(
      url: 'fingerprint-devices/employee-overview',
      token: token,
    );
    return _decodeList(data, FingerprintOverviewModel.fromJson);
  }

  /// `GET /fingerprint-devices/employees/{id}/enrollments`
  Future<List<FingerprintEnrollmentModel>> getEmployeeEnrollments({
    required String employeeId,
    String? token,
  }) async {
    log('Fetching enrollments for employee: $employeeId');

    final data = await Api().get(
      url: 'fingerprint-devices/employees/$employeeId/enrollments',
      token: token,
    );
    return _decodeList(data, FingerprintEnrollmentModel.fromJson);
  }

  /// `POST /fingerprint-devices/employees/{id}/enrollments`
  Future<FingerprintEnrollmentModel> enrollEmployeeFingerprint({
    required String employeeId,
    required SaveFingerprintEnrollmentRequestModel body,
    String? token,
  }) async {
    log('Enrolling employee $employeeId on device ${body.deviceId}');

    final response = await Api().post(
      url: 'fingerprint-devices/employees/$employeeId/enrollments',
      body: body.toJson(),
      token: token,
    );
    return FingerprintEnrollmentModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `PUT /fingerprint-devices/employees/{id}/enrollments/{enrollmentId}`
  ///
  /// Corrects which terminal and which number — never which person: see
  /// [SaveFingerprintEnrollmentRequestModel].
  Future<FingerprintEnrollmentModel> updateEmployeeEnrollment({
    required String employeeId,
    required String enrollmentId,
    required SaveFingerprintEnrollmentRequestModel body,
    String? token,
  }) async {
    log('Updating enrollment $enrollmentId for employee $employeeId');

    final response = await Api().put(
      url:
          'fingerprint-devices/employees/$employeeId/enrollments/$enrollmentId',
      body: body.toJson(),
      token: token,
    );
    return FingerprintEnrollmentModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `DELETE /fingerprint-devices/employees/{id}/enrollments/{enrollmentId}`
  Future<void> deleteEmployeeEnrollment({
    required String employeeId,
    required String enrollmentId,
    String? token,
  }) async {
    log('Deleting enrollment $enrollmentId for employee $employeeId');

    await Api().delete(
      url:
          'fingerprint-devices/employees/$employeeId/enrollments/$enrollmentId',
      token: token,
    );
  }

  // ---- Holidays ---------------------------------------------------------

  /// `GET /Holidays`
  Future<List<HolidayModel>> getHolidays({
    String? employeeId,
    DateTime? from,
    DateTime? to,
    String? token,
  }) async {
    log('Fetching holidays');

    final data = await Api().get(
      url:
          'Holidays${_query([
            MapEntry('employeeId', employeeId),
            MapEntry('from', _date(from)),
            MapEntry('to', _date(to)),
          ])}',
      token: token,
    );
    return _decodeList(data, HolidayModel.fromJson);
  }

  /// `POST /Holidays`
  Future<HolidayModel> createHoliday({
    required SaveHolidayRequestModel body,
    String? token,
  }) async {
    log('Creating holiday: ${body.name}');

    final response = await Api().post(
      url: 'Holidays',
      body: body.toJson(),
      token: token,
    );
    return HolidayModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /Holidays/{id}` — recalculates every day it covered.
  Future<void> deleteHoliday({required String id, String? token}) async {
    log('Deleting holiday: $id');

    await Api().delete(url: 'Holidays/$id', token: token);
  }

  // ---- Leaves -----------------------------------------------------------

  /// `GET /Leaves`
  ///
  /// Self-scoped without `Leaves:FullAccess`: an ordinary employee sees their
  /// own requests and nobody else's, enforced server-side.
  Future<List<LeaveModel>> getLeaves({
    String? employeeId,
    LeaveStatus? status,
    DateTime? from,
    DateTime? to,
    String? token,
  }) async {
    log('Fetching leaves');

    final data = await Api().get(
      url:
          'Leaves${_query([
            MapEntry('employeeId', employeeId),
            MapEntry('status', status?.value.toString()),
            MapEntry('from', _date(from)),
            MapEntry('to', _date(to)),
          ])}',
      token: token,
    );
    return _decodeList(data, LeaveModel.fromJson);
  }

  /// `POST /Leaves` — an administrator recording a leave for someone.
  Future<LeaveModel> createLeave({
    required CreateLeaveRequestModel body,
    String? token,
  }) async {
    log('Creating leave for employee: ${body.employeeId}');

    final response = await Api().post(
      url: 'Leaves',
      body: body.toJson(),
      token: token,
    );
    return LeaveModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /Leaves/request` — the signed-in employee asking for their own.
  Future<LeaveModel> requestLeave({
    required SaveLeaveRequestModel body,
    String? token,
  }) async {
    log('Requesting a leave');

    final response = await Api().post(
      url: 'Leaves/request',
      body: body.toJson(),
      token: token,
    );
    return LeaveModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PUT /Leaves/{id}`
  Future<LeaveModel> updateLeave({
    required String id,
    required SaveLeaveRequestModel body,
    String? token,
  }) async {
    log('Updating leave: $id');

    final response = await Api().put(
      url: 'Leaves/$id',
      body: body.toJson(),
      token: token,
    );
    return LeaveModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PUT /Leaves/{id}/decide` — approve or refuse.
  Future<LeaveModel> decideLeave({
    required String id,
    required bool approve,
    String? token,
  }) async {
    log('Deciding leave $id: approve=$approve');

    final response = await Api().put(
      url: 'Leaves/$id/decide',
      body: {'approve': approve},
      token: token,
    );
    return LeaveModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /Leaves/{id}` — recalculates every day it covered.
  Future<void> deleteLeave({required String id, String? token}) async {
    log('Deleting leave: $id');

    await Api().delete(url: 'Leaves/$id', token: token);
  }

  // ---- Salary systems ---------------------------------------------------

  /// `GET /employee-salary-systems/employee/{id}` — the pay history.
  Future<List<EmployeeSalarySystemModel>> getEmployeeSalarySystems({
    required String employeeId,
    String? token,
  }) async {
    log('Fetching salary history for employee: $employeeId');

    final data = await Api().get(
      url: 'employee-salary-systems/employee/$employeeId',
      token: token,
    );
    return _decodeList(data, EmployeeSalarySystemModel.fromJson);
  }

  /// `GET /employee-salary-systems/employee/{id}/active`
  Future<EmployeeSalarySystemModel?> getActiveSalarySystem({
    required String employeeId,
    String? token,
  }) async {
    log('Fetching active salary system for employee: $employeeId');

    final data = await Api().get(
      url: 'employee-salary-systems/employee/$employeeId/active',
      token: token,
    );
    // An employee with no pay configured yet is an ordinary answer.
    if (data is! Map<String, dynamic>) return null;
    return EmployeeSalarySystemModel.fromJson(data);
  }

  /// `POST /employee-salary-systems` — opens a new pay spell.
  Future<EmployeeSalarySystemModel> saveEmployeeSalarySystem({
    required SaveEmployeeSalarySystemRequestModel body,
    String? token,
  }) async {
    log('Saving salary system for employee: ${body.employeeId}');

    final response = await Api().post(
      url: 'employee-salary-systems',
      body: body.toJson(),
      token: token,
    );
    return EmployeeSalarySystemModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ---- Salary exceptions ------------------------------------------------

  /// `GET /SalaryExceptions/employee/{id}`
  Future<List<SalaryExceptionModel>> getSalaryExceptions({
    required String employeeId,
    String? token,
  }) async {
    log('Fetching salary exceptions for employee: $employeeId');

    final data = await Api().get(
      url: 'SalaryExceptions/employee/$employeeId',
      token: token,
    );
    return _decodeList(data, SalaryExceptionModel.fromJson);
  }

  /// `POST /SalaryExceptions`
  Future<SalaryExceptionModel> createSalaryException({
    required SaveSalaryExceptionRequestModel body,
    String? token,
  }) async {
    log('Creating salary exception for employee: ${body.employeeId}');

    final response = await Api().post(
      url: 'SalaryExceptions',
      body: body.toJson(),
      token: token,
    );
    return SalaryExceptionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `PUT /SalaryExceptions/{id}/deactivate`
  ///
  /// Deactivated, never deleted: a statement that already folded it in has to
  /// stay explainable afterwards.
  Future<void> deactivateSalaryException({
    required String id,
    String? token,
  }) async {
    log('Deactivating salary exception: $id');

    await Api().put(
      url: 'SalaryExceptions/$id/deactivate',
      body: const <String, dynamic>{},
      token: token,
    );
  }

  // ---- Payroll ----------------------------------------------------------

  /// `POST /Payroll/generate`
  ///
  /// No date range: each employee's own pay period decides the window around
  /// the anchor date, so a weekly and a monthly employee generated in one call
  /// get different ones.
  Future<List<SalaryStatementModel>> generatePayroll({
    required GeneratePayrollRequestModel body,
    String? token,
  }) async {
    log('Generating payroll around ${ApiTime.formatDate(body.anchorDate)}');

    final response = await Api().post(
      url: 'Payroll/generate',
      body: body.toJson(),
      token: token,
    );
    return _decodeList(response.data, SalaryStatementModel.fromJson);
  }

  /// `GET /Payroll/coverage` — who has not been paid for this period yet.
  Future<List<PayrollCoverageEntryModel>> getPayrollCoverage({
    DateTime? anchorDate,
    String? token,
  }) async {
    log('Fetching payroll coverage');

    final data = await Api().get(
      url:
          'Payroll/coverage${_query([MapEntry('anchorDate', _date(anchorDate))])}',
      token: token,
    );
    return _decodeList(data, PayrollCoverageEntryModel.fromJson);
  }

  /// `GET /Payroll/statements`
  Future<List<SalaryStatementModel>> getSalaryStatements({
    DateTime? periodStart,
    DateTime? periodEnd,
    String? employeeId,
    SalaryStatementStatus? status,
    String? token,
  }) async {
    log('Fetching salary statements');

    final data = await Api().get(
      url:
          'Payroll/statements${_query([
            MapEntry('periodStart', _date(periodStart)),
            MapEntry('periodEnd', _date(periodEnd)),
            MapEntry('employeeId', employeeId),
            MapEntry('status', status?.value.toString()),
          ])}',
      token: token,
    );
    return _decodeList(data, SalaryStatementModel.fromJson);
  }

  /// `PUT /Payroll/statements/{id}/approve` — closes the days it covers.
  Future<SalaryStatementModel> approveSalaryStatement({
    required String id,
    String? token,
  }) async {
    log('Approving salary statement: $id');

    final response = await Api().put(
      url: 'Payroll/statements/$id/approve',
      body: const <String, dynamic>{},
      token: token,
    );
    return SalaryStatementModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `PUT /Payroll/statements/{id}/mark-paid`
  Future<SalaryStatementModel> markSalaryStatementPaid({
    required String id,
    String? token,
  }) async {
    log('Marking salary statement paid: $id');

    final response = await Api().put(
      url: 'Payroll/statements/$id/mark-paid',
      body: const <String, dynamic>{},
      token: token,
    );
    return SalaryStatementModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `PUT /Payroll/statements/{id}/revert` — back to draft.
  ///
  /// The way an approved period is reopened so a corrected punch or a
  /// back-dated leave can finally be taken into account.
  Future<SalaryStatementModel> revertSalaryStatement({
    required String id,
    String? token,
  }) async {
    log('Reverting salary statement: $id');

    final response = await Api().put(
      url: 'Payroll/statements/$id/revert',
      body: const <String, dynamic>{},
      token: token,
    );
    return SalaryStatementModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `DELETE /Payroll/statements/{id}` — drafts only.
  Future<void> deleteSalaryStatement({
    required String id,
    String? token,
  }) async {
    log('Deleting salary statement: $id');

    await Api().delete(url: 'Payroll/statements/$id', token: token);
  }
}
