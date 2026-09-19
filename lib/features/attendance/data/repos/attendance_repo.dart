import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/attendance_api.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/attendance/data/models/daily_attendance_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/employee_work_system_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/fingerprint_device_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/leave_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/punch_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/work_shift_model.dart';
import 'package:dio/dio.dart';

/// Attendance: shifts, who is on them, the days that come out of that, the
/// punches behind those days, the terminals that record them, and the leaves
/// and holidays that excuse them.
class AttendanceRepo {
  AttendanceRepo(this._apiService);

  final ApiService _apiService;

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  /// The try/catch every call shares. Each one names what it was doing so a
  /// log line says which of fifty endpoints failed.
  Future<Either<Failure, T>> _guard<T>(
    String what,
    Future<T> Function() request,
  ) async {
    try {
      return right(await request());
    } on DioException catch (e) {
      log('DioException while $what: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while $what: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  // ---- Work shifts ------------------------------------------------------

  Future<Either<Failure, List<WorkShiftModel>>> getWorkShifts() =>
      _guard('fetching work shifts', () => _apiService.getWorkShifts(token: _token));

  Future<Either<Failure, WorkShiftModel>> getWorkShiftById(String id) =>
      _guard(
        'fetching a work shift',
        () => _apiService.getWorkShiftById(id: id, token: _token),
      );

  Future<Either<Failure, WorkShiftModel>> createWorkShift(
    SaveWorkShiftRequestModel body,
  ) => _guard(
    'creating a work shift',
    () => _apiService.createWorkShift(body: body, token: _token),
  );

  Future<Either<Failure, WorkShiftModel>> updateWorkShift({
    required String id,
    required SaveWorkShiftRequestModel body,
  }) => _guard(
    'updating a work shift',
    () => _apiService.updateWorkShift(id: id, body: body, token: _token),
  );

  Future<Either<Failure, void>> deleteWorkShift(String id) => _guard(
    'deleting a work shift',
    () => _apiService.deleteWorkShift(id: id, token: _token),
  );

  /// What editing this shift's rules would disturb — read before saving.
  Future<Either<Failure, WorkShiftAttendanceImpactModel>>
  getWorkShiftAttendanceImpact(String id) => _guard(
    'fetching a work shift\'s attendance impact',
    () => _apiService.getWorkShiftAttendanceImpact(id: id, token: _token),
  );

  // ---- Employee → shift spells -----------------------------------------

  Future<Either<Failure, List<EmployeeWorkSystemModel>>> getEmployeeWorkSystems(
    String employeeId,
  ) => _guard(
    'fetching an employee\'s work systems',
    () => _apiService.getEmployeeWorkSystems(
      employeeId: employeeId,
      token: _token,
    ),
  );

  Future<Either<Failure, EmployeeWorkSystemModel?>> getActiveWorkSystem(
    String employeeId,
  ) => _guard(
    'fetching an employee\'s active work system',
    () => _apiService.getActiveEmployeeWorkSystem(
      employeeId: employeeId,
      token: _token,
    ),
  );

  Future<Either<Failure, List<EmployeeWorkSystemModel>>> getWorkShiftRoster(
    String workShiftId,
  ) => _guard(
    'fetching a shift roster',
    () =>
        _apiService.getWorkShiftRoster(workShiftId: workShiftId, token: _token),
  );

  Future<Either<Failure, EmployeeWorkSystemModel>> saveEmployeeWorkSystem(
    SaveEmployeeWorkSystemRequestModel body,
  ) => _guard(
    'saving an employee work system',
    () => _apiService.saveEmployeeWorkSystem(body: body, token: _token),
  );

  Future<Either<Failure, List<EmployeeWorkSystemModel>>> assignWorkShift(
    AssignWorkShiftEmployeesRequestModel body,
  ) => _guard(
    'assigning employees to a shift',
    () => _apiService.assignWorkShiftEmployees(body: body, token: _token),
  );

  // ---- Daily attendance -------------------------------------------------

  Future<Either<Failure, List<DailyAttendanceModel>>> getEmployeeAttendance({
    required String employeeId,
    DateTime? from,
    DateTime? to,
  }) => _guard(
    'fetching an employee\'s attendance',
    () => _apiService.getEmployeeAttendance(
      employeeId: employeeId,
      from: from,
      to: to,
      token: _token,
    ),
  );

  Future<Either<Failure, List<DailyAttendanceModel>>> getAttendanceForDay(
    DateTime date,
  ) => _guard(
    'fetching a day\'s attendance',
    () => _apiService.getAttendanceForDay(date: date, token: _token),
  );

  Future<Either<Failure, List<DailyAttendanceModel>>> getAttendanceForRange({
    required DateTime from,
    required DateTime to,
  }) => _guard(
    'fetching an attendance range',
    () => _apiService.getAttendanceForRange(from: from, to: to, token: _token),
  );

  /// Recomputes one day. Required after any edit to a punch, leave or holiday
  /// — the read model is a cache of an answer, not the answer.
  Future<Either<Failure, DailyAttendanceModel>> recalculateDay({
    required String employeeId,
    required DateTime date,
  }) => _guard(
    'recalculating a day',
    () => _apiService.recalculateAttendanceDay(
      employeeId: employeeId,
      date: date,
      token: _token,
    ),
  );

  Future<Either<Failure, int>> recalculateRange({
    required String employeeId,
    required DateTime from,
    required DateTime to,
  }) => _guard(
    'recalculating an attendance range',
    () => _apiService.recalculateAttendanceRange(
      employeeId: employeeId,
      from: from,
      to: to,
      token: _token,
    ),
  );

  // ---- Punches ----------------------------------------------------------

  Future<Either<Failure, List<PunchModel>>> getPunchesForDay({
    required String employeeId,
    required DateTime date,
  }) => _guard(
    'fetching a day\'s punches',
    () => _apiService.getPunchesForDay(
      employeeId: employeeId,
      date: date,
      token: _token,
    ),
  );

  Future<Either<Failure, DailyAttendanceModel>> addManualPunch(
    AddManualPunchRequestModel body,
  ) => _guard(
    'adding a manual punch',
    () => _apiService.addManualPunch(body: body, token: _token),
  );

  Future<Either<Failure, DailyAttendanceModel>> updatePunch({
    required String id,
    required DateTime timestamp,
  }) => _guard(
    'updating a punch',
    () => _apiService.updatePunch(id: id, timestamp: timestamp, token: _token),
  );

  Future<Either<Failure, DailyAttendanceModel?>> deletePunch(String id) =>
      _guard(
        'deleting a punch',
        () => _apiService.deletePunch(id: id, token: _token),
      );

  // ---- Fingerprint devices ---------------------------------------------

  Future<Either<Failure, List<FingerprintDeviceModel>>>
  getFingerprintDevices() => _guard(
    'fetching fingerprint devices',
    () => _apiService.getFingerprintDevices(token: _token),
  );

  Future<Either<Failure, FingerprintDeviceModel>> createFingerprintDevice(
    SaveFingerprintDeviceRequestModel body,
  ) => _guard(
    'registering a fingerprint device',
    () => _apiService.createFingerprintDevice(body: body, token: _token),
  );

  Future<Either<Failure, FingerprintDeviceModel>> updateFingerprintDevice({
    required String id,
    required SaveFingerprintDeviceRequestModel body,
  }) => _guard(
    'updating a fingerprint device',
    () =>
        _apiService.updateFingerprintDevice(id: id, body: body, token: _token),
  );

  Future<Either<Failure, void>> deleteFingerprintDevice(String id) => _guard(
    'deleting a fingerprint device',
    () => _apiService.deleteFingerprintDevice(id: id, token: _token),
  );

  Future<Either<Failure, List<FingerprintOverviewModel>>>
  getFingerprintOverview() => _guard(
    'fetching the fingerprint overview',
    () => _apiService.getFingerprintOverview(token: _token),
  );

  Future<Either<Failure, FingerprintEnrollmentModel>> enrollFingerprint({
    required String employeeId,
    required SaveFingerprintEnrollmentRequestModel body,
  }) => _guard(
    'enrolling a fingerprint',
    () => _apiService.enrollEmployeeFingerprint(
      employeeId: employeeId,
      body: body,
      token: _token,
    ),
  );

  Future<Either<Failure, FingerprintEnrollmentModel>> updateEnrollment({
    required String employeeId,
    required String enrollmentId,
    required SaveFingerprintEnrollmentRequestModel body,
  }) => _guard(
    'updating a fingerprint enrollment',
    () => _apiService.updateEmployeeEnrollment(
      employeeId: employeeId,
      enrollmentId: enrollmentId,
      body: body,
      token: _token,
    ),
  );

  Future<Either<Failure, void>> deleteEnrollment({
    required String employeeId,
    required String enrollmentId,
  }) => _guard(
    'deleting a fingerprint enrollment',
    () => _apiService.deleteEmployeeEnrollment(
      employeeId: employeeId,
      enrollmentId: enrollmentId,
      token: _token,
    ),
  );

  // ---- Holidays ---------------------------------------------------------

  Future<Either<Failure, List<HolidayModel>>> getHolidays({
    String? employeeId,
    DateTime? from,
    DateTime? to,
  }) => _guard(
    'fetching holidays',
    () => _apiService.getHolidays(
      employeeId: employeeId,
      from: from,
      to: to,
      token: _token,
    ),
  );

  Future<Either<Failure, HolidayModel>> createHoliday(
    SaveHolidayRequestModel body,
  ) => _guard(
    'creating a holiday',
    () => _apiService.createHoliday(body: body, token: _token),
  );

  Future<Either<Failure, void>> deleteHoliday(String id) => _guard(
    'deleting a holiday',
    () => _apiService.deleteHoliday(id: id, token: _token),
  );

  // ---- Leaves -----------------------------------------------------------

  Future<Either<Failure, List<LeaveModel>>> getLeaves({
    String? employeeId,
    LeaveStatus? status,
    DateTime? from,
    DateTime? to,
  }) => _guard(
    'fetching leaves',
    () => _apiService.getLeaves(
      employeeId: employeeId,
      status: status,
      from: from,
      to: to,
      token: _token,
    ),
  );

  Future<Either<Failure, LeaveModel>> createLeave(
    CreateLeaveRequestModel body,
  ) => _guard(
    'creating a leave',
    () => _apiService.createLeave(body: body, token: _token),
  );

  Future<Either<Failure, LeaveModel>> requestLeave(
    SaveLeaveRequestModel body,
  ) => _guard(
    'requesting a leave',
    () => _apiService.requestLeave(body: body, token: _token),
  );

  Future<Either<Failure, LeaveModel>> updateLeave({
    required String id,
    required SaveLeaveRequestModel body,
  }) => _guard(
    'updating a leave',
    () => _apiService.updateLeave(id: id, body: body, token: _token),
  );

  Future<Either<Failure, LeaveModel>> decideLeave({
    required String id,
    required bool approve,
  }) => _guard(
    'deciding a leave',
    () => _apiService.decideLeave(id: id, approve: approve, token: _token),
  );

  Future<Either<Failure, void>> deleteLeave(String id) => _guard(
    'deleting a leave',
    () => _apiService.deleteLeave(id: id, token: _token),
  );
}
