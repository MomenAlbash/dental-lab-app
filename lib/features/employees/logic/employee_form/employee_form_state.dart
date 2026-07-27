import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';

sealed class EmployeeFormState {
  const EmployeeFormState();
}

class EmployeeFormInitial extends EmployeeFormState {
  const EmployeeFormInitial();
}

class EmployeeFormSubmitting extends EmployeeFormState {
  const EmployeeFormSubmitting();
}

class EmployeeFormSuccess extends EmployeeFormState {
  const EmployeeFormSuccess(this.employee);
  final EmployeeModel employee;
}

class EmployeeFormError extends EmployeeFormState {
  const EmployeeFormError(this.message);
  final String message;
}
