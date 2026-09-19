import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/attendance_api.dart';
import 'package:dental_lab_app/features/payroll/data/models/payroll_enums.dart';
import 'package:dental_lab_app/features/payroll/data/models/salary_model.dart';
import 'package:dio/dio.dart';

/// Payroll: what each employee is paid, the standing adjustments to it, and
/// the statements that come out of running it over a period.
class PayrollRepo {
  PayrollRepo(this._apiService);

  final ApiService _apiService;

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

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

  // ---- Salary systems ---------------------------------------------------

  /// The employee's pay history — a list of dated spells, not one field.
  Future<Either<Failure, List<EmployeeSalarySystemModel>>> getSalarySystems(
    String employeeId,
  ) => _guard(
    'fetching an employee\'s salary systems',
    () => _apiService.getEmployeeSalarySystems(
      employeeId: employeeId,
      token: _token,
    ),
  );

  Future<Either<Failure, EmployeeSalarySystemModel?>> getActiveSalarySystem(
    String employeeId,
  ) => _guard(
    'fetching an employee\'s active salary system',
    () =>
        _apiService.getActiveSalarySystem(employeeId: employeeId, token: _token),
  );

  Future<Either<Failure, EmployeeSalarySystemModel>> saveSalarySystem(
    SaveEmployeeSalarySystemRequestModel body,
  ) => _guard(
    'saving a salary system',
    () => _apiService.saveEmployeeSalarySystem(body: body, token: _token),
  );

  // ---- Salary exceptions ------------------------------------------------

  Future<Either<Failure, List<SalaryExceptionModel>>> getSalaryExceptions(
    String employeeId,
  ) => _guard(
    'fetching salary exceptions',
    () => _apiService.getSalaryExceptions(
      employeeId: employeeId,
      token: _token,
    ),
  );

  Future<Either<Failure, SalaryExceptionModel>> createSalaryException(
    SaveSalaryExceptionRequestModel body,
  ) => _guard(
    'creating a salary exception',
    () => _apiService.createSalaryException(body: body, token: _token),
  );

  /// Deactivated rather than deleted — a statement that already folded it in
  /// has to stay explainable.
  Future<Either<Failure, void>> deactivateSalaryException(String id) => _guard(
    'deactivating a salary exception',
    () => _apiService.deactivateSalaryException(id: id, token: _token),
  );

  // ---- Payroll ----------------------------------------------------------

  Future<Either<Failure, List<SalaryStatementModel>>> generatePayroll(
    GeneratePayrollRequestModel body,
  ) => _guard(
    'generating payroll',
    () => _apiService.generatePayroll(body: body, token: _token),
  );

  /// Who has no statement yet for their own current period — the list to read
  /// *before* running payroll.
  Future<Either<Failure, List<PayrollCoverageEntryModel>>> getCoverage({
    DateTime? anchorDate,
  }) => _guard(
    'fetching payroll coverage',
    () => _apiService.getPayrollCoverage(anchorDate: anchorDate, token: _token),
  );

  Future<Either<Failure, List<SalaryStatementModel>>> getStatements({
    DateTime? periodStart,
    DateTime? periodEnd,
    String? employeeId,
    SalaryStatementStatus? status,
  }) => _guard(
    'fetching salary statements',
    () => _apiService.getSalaryStatements(
      periodStart: periodStart,
      periodEnd: periodEnd,
      employeeId: employeeId,
      status: status,
      token: _token,
    ),
  );

  Future<Either<Failure, SalaryStatementModel>> approveStatement(String id) =>
      _guard(
        'approving a salary statement',
        () => _apiService.approveSalaryStatement(id: id, token: _token),
      );

  Future<Either<Failure, SalaryStatementModel>> markStatementPaid(String id) =>
      _guard(
        'marking a salary statement paid',
        () => _apiService.markSalaryStatementPaid(id: id, token: _token),
      );

  /// Reopens an approved period so a corrected punch or a back-dated leave can
  /// finally be accounted for.
  Future<Either<Failure, SalaryStatementModel>> revertStatement(String id) =>
      _guard(
        'reverting a salary statement',
        () => _apiService.revertSalaryStatement(id: id, token: _token),
      );

  Future<Either<Failure, void>> deleteStatement(String id) => _guard(
    'deleting a salary statement',
    () => _apiService.deleteSalaryStatement(id: id, token: _token),
  );
}
