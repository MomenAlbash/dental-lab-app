import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';

sealed class EmployeesState {
  const EmployeesState();
}

class EmployeesInitial extends EmployeesState {
  const EmployeesInitial();
}

class EmployeesLoading extends EmployeesState {
  const EmployeesLoading();
}

class EmployeesLoaded extends EmployeesState {
  const EmployeesLoaded(this.employees);
  final List<EmployeeModel> employees;
}

class EmployeesError extends EmployeesState {
  const EmployeesError(this.message);
  final String message;
}

class EmployeeDeleted extends EmployeesState {
  const EmployeeDeleted();
}

class EmployeeDeleteError extends EmployeesState {
  const EmployeeDeleteError(this.message);
  final String message;
}
