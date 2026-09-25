import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/stage_pay/data/models/stage_pay_models.dart';

sealed class StageEarningsState {
  const StageEarningsState({
    required this.from,
    required this.to,
    this.employeeId,
    this.employees = const [],
  });

  /// The filters travel with every state so the controls never blank out
  /// while a new period loads.
  final DateTime from;
  final DateTime to;
  final String? employeeId;
  final List<EmployeeModel> employees;
}

class StageEarningsLoading extends StageEarningsState {
  const StageEarningsLoading({
    required super.from,
    required super.to,
    super.employeeId,
    super.employees,
  });
}

class StageEarningsError extends StageEarningsState {
  const StageEarningsError(
    this.message, {
    required super.from,
    required super.to,
    super.employeeId,
    super.employees,
  });

  final String message;
}

class StageEarningsLoaded extends StageEarningsState {
  const StageEarningsLoaded({
    required this.rows,
    required super.from,
    required super.to,
    super.employeeId,
    super.employees,
  });

  final List<EmployeeStageEarningModel> rows;

  double get total => EmployeeStageEarningModel.totalOf(rows);
}
