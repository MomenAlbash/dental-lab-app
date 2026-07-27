import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';

sealed class EmployeeDetailsState {
  const EmployeeDetailsState();
}

class EmployeeDetailsInitial extends EmployeeDetailsState {
  const EmployeeDetailsInitial();
}

class EmployeeDetailsLoading extends EmployeeDetailsState {
  const EmployeeDetailsLoading();
}

class EmployeeDetailsLoaded extends EmployeeDetailsState {
  const EmployeeDetailsLoaded(this.employee, {this.isBusy = false});

  final EmployeeModel employee;

  /// True while a file upload or deletion is in flight.
  final bool isBusy;
}

class EmployeeDetailsError extends EmployeeDetailsState {
  const EmployeeDetailsError(this.message);
  final String message;
}

/// Transient failure of a file action — surfaced as a toast.
class EmployeeDetailsActionError extends EmployeeDetailsState {
  const EmployeeDetailsActionError(this.message);
  final String message;
}

/// Transient success of a file action — surfaced as a toast.
class EmployeeDetailsActionSuccess extends EmployeeDetailsState {
  const EmployeeDetailsActionSuccess(this.message);
  final String message;
}
