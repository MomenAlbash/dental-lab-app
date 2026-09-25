import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/stage_pay/data/repos/stage_pay_repo.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_earnings/stage_earnings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Stages finished over a period, and what each paid — for everyone or one
/// employee.
class StageEarningsCubit extends Cubit<StageEarningsState> {
  StageEarningsCubit(this._repo, this._employeesRepo, {DateTime? today})
    : _from = _monthStart(today ?? DateTime.now()),
      _to = _dateOnly(today ?? DateTime.now()),
      super(
        StageEarningsLoading(
          from: _monthStart(today ?? DateTime.now()),
          to: _dateOnly(today ?? DateTime.now()),
        ),
      );

  final StagePayRepo _repo;
  final EmployeesRepo _employeesRepo;

  DateTime _from;
  DateTime _to;
  String? _employeeId;
  List<EmployeeModel> _employees = const [];

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _monthStart(DateTime d) => DateTime(d.year, d.month);

  /// Loads the employee filter once, then the rows.
  Future<void> init() async {
    final employees = await _employeesRepo.getEmployees();
    if (isClosed) return;
    // Only the filter needs these; without them the list still works for
    // everyone.
    _employees = employees.fold((_) => const [], (list) => list);
    await load();
  }

  Future<void> load() async {
    emit(
      StageEarningsLoading(
        from: _from,
        to: _to,
        employeeId: _employeeId,
        employees: _employees,
      ),
    );

    final result = await _repo.getEarnings(
      from: _from,
      to: _to,
      employeeId: _employeeId,
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        StageEarningsError(
          failure.errorMessage,
          from: _from,
          to: _to,
          employeeId: _employeeId,
          employees: _employees,
        ),
      ),
      (rows) => emit(
        StageEarningsLoaded(
          rows: rows,
          from: _from,
          to: _to,
          employeeId: _employeeId,
          employees: _employees,
        ),
      ),
    );
  }

  Future<void> setRange(DateTime from, DateTime to) async {
    _from = _dateOnly(from);
    _to = _dateOnly(to);
    await load();
  }

  /// Null shows everyone.
  Future<void> setEmployee(String? employeeId) async {
    _employeeId = employeeId;
    await load();
  }
}
