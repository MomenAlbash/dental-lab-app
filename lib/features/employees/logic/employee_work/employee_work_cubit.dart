import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/attendance/data/models/employee_work_system_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/fingerprint_device_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/work_shift_model.dart';
import 'package:dental_lab_app/features/attendance/data/repos/attendance_repo.dart';
import 'package:dental_lab_app/features/payroll/data/models/salary_model.dart';
import 'package:dental_lab_app/features/payroll/data/repos/payroll_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class EmployeeWorkState {
  const EmployeeWorkState();
}

class EmployeeWorkLoading extends EmployeeWorkState {
  const EmployeeWorkLoading();
}

class EmployeeWorkError extends EmployeeWorkState {
  const EmployeeWorkError(this.message);
  final String message;
}

/// Everything about how one employee works and is paid.
class EmployeeWorkLoaded extends EmployeeWorkState {
  const EmployeeWorkLoaded({
    this.shiftHistory = const [],
    this.salaryHistory = const [],
    this.exceptions = const [],
    this.enrollments = const [],
    this.shifts = const [],
    this.isBusy = false,
  });

  /// Dated spells, newest arrangement not necessarily first — the server's
  /// order is kept, and the active row is marked rather than sorted to the
  /// top, so the history still reads chronologically.
  final List<EmployeeWorkSystemModel> shiftHistory;
  final List<EmployeeSalarySystemModel> salaryHistory;

  /// Standing payroll adjustments.
  final List<SalaryExceptionModel> exceptions;

  /// Which terminal numbers this person punches on.
  final List<FingerprintEnrollmentModel> enrollments;

  /// The shift catalogue, for the assignment picker.
  final List<WorkShiftModel> shifts;

  final bool isBusy;

  EmployeeWorkSystemModel? get activeShift {
    for (final spell in shiftHistory) {
      if (spell.isActive) return spell;
    }
    return null;
  }

  EmployeeSalarySystemModel? get activeSalary {
    for (final spell in salaryHistory) {
      if (spell.isActive) return spell;
    }
    return null;
  }

  /// Exceptions still in force — a deactivated one stays in the list as
  /// history but must not read as active.
  List<SalaryExceptionModel> get activeExceptions => [
    for (final exception in exceptions)
      if (exception.isActive) exception,
  ];

  EmployeeWorkLoaded copyWith({bool? isBusy}) => EmployeeWorkLoaded(
    shiftHistory: shiftHistory,
    salaryHistory: salaryHistory,
    exceptions: exceptions,
    enrollments: enrollments,
    shifts: shifts,
    isBusy: isBusy ?? this.isBusy,
  );
}

class EmployeeWorkActionSuccess extends EmployeeWorkState {
  const EmployeeWorkActionSuccess(this.message);
  final String message;
}

class EmployeeWorkActionError extends EmployeeWorkState {
  const EmployeeWorkActionError(this.message);
  final String message;
}

/// One employee's shift, pay, standing adjustments and terminal codes.
///
/// Four reads on one screen because they answer one question — "how does this
/// person work here" — and a user checking why somebody's payslip looks wrong
/// moves between all four.
class EmployeeWorkCubit extends Cubit<EmployeeWorkState> {
  EmployeeWorkCubit(this._attendance, this._payroll)
    : super(const EmployeeWorkLoading());

  final AttendanceRepo _attendance;
  final PayrollRepo _payroll;

  String? _employeeId;

  Future<void> load(String employeeId) async {
    _employeeId = employeeId;
    emit(const EmployeeWorkLoading());

    // Started together: four sequential round-trips would make the last
    // section arrive visibly after the first.
    final shiftRequest = _attendance.getEmployeeWorkSystems(employeeId);
    final salaryRequest = _payroll.getSalarySystems(employeeId);
    final exceptionsRequest = _payroll.getSalaryExceptions(employeeId);
    final enrollmentsRequest = _attendance.getFingerprintOverview();
    final shiftsRequest = _attendance.getWorkShifts();

    final shiftHistory = await shiftRequest;
    final salaryHistory = await salaryRequest;
    final exceptions = await exceptionsRequest;
    final overview = await enrollmentsRequest;
    final shifts = await shiftsRequest;
    if (isClosed) return;

    // The shift history is the spine of this screen: without it there is
    // nothing to show. The rest degrade to empty sections instead of taking
    // the whole sheet down.
    shiftHistory.fold(
      (failure) => emit(EmployeeWorkError(failure.errorMessage)),
      (history) => emit(
        EmployeeWorkLoaded(
          shiftHistory: history,
          salaryHistory: salaryHistory.fold((_) => const [], (list) => list),
          exceptions: exceptions.fold((_) => const [], (list) => list),
          enrollments: overview.fold((_) => const [], (rows) {
            for (final row in rows) {
              if (row.employeeId == employeeId) return row.enrollments;
            }
            return const [];
          }),
          shifts: shifts.fold((_) => const [], (list) => list),
        ),
      ),
    );
  }

  /// Opens a new shift spell — closing whatever one is running.
  ///
  /// [workShiftId] null takes them off every shift, which is a real
  /// arrangement (a day labourer, somebody on call), not a deletion.
  Future<void> assignShift(String? workShiftId) async {
    final employeeId = _employeeId;
    if (employeeId == null) return;

    await _write(
      workShiftId == null ? 'تم إخراج الموظف من الوردية' : 'تم تعيين الوردية',
      () => _attendance.saveEmployeeWorkSystem(
        SaveEmployeeWorkSystemRequestModel(
          employeeId: employeeId,
          workShiftId: workShiftId,
        ),
      ),
    );
  }

  /// Opens a new pay spell. A raise closes the old one, so a statement for a
  /// past period is still computed against the rate that applied then.
  Future<void> saveSalary(SaveEmployeeSalarySystemRequestModel body) =>
      _write('تم حفظ نظام الراتب', () => _payroll.saveSalarySystem(body));

  Future<void> addException(SaveSalaryExceptionRequestModel body) =>
      _write('تمت إضافة الاستثناء', () => _payroll.createSalaryException(body));

  /// Deactivated, never deleted — a statement that already folded it in has
  /// to stay explainable.
  Future<void> deactivateException(String id) => _write(
    'تم إلغاء تفعيل الاستثناء',
    () => _payroll.deactivateSalaryException(id),
  );

  Future<void> enrollFingerprint({
    required String deviceId,
    required String deviceUserId,
  }) async {
    final employeeId = _employeeId;
    if (employeeId == null) return;

    await _write(
      'تم ربط البصمة',
      () => _attendance.enrollFingerprint(
        employeeId: employeeId,
        body: SaveFingerprintEnrollmentRequestModel(
          deviceId: deviceId,
          deviceUserId: deviceUserId,
        ),
      ),
    );
  }

  Future<void> deleteEnrollment(String enrollmentId) async {
    final employeeId = _employeeId;
    if (employeeId == null) return;

    await _write(
      'تم إلغاء ربط البصمة',
      () => _attendance.deleteEnrollment(
        employeeId: employeeId,
        enrollmentId: enrollmentId,
      ),
    );
  }

  Future<void> _write<T>(
    String successMessage,
    Future<Either<Failure, T>> Function() request,
  ) async {
    final employeeId = _employeeId;
    final current = state;
    if (employeeId == null) return;
    if (current is EmployeeWorkLoaded) emit(current.copyWith(isBusy: true));

    final result = await request();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(EmployeeWorkActionError(failure.errorMessage));
        if (current is EmployeeWorkLoaded) emit(current);
      },
      (_) async {
        emit(EmployeeWorkActionSuccess(successMessage));
        await load(employeeId);
      },
    );
  }
}
