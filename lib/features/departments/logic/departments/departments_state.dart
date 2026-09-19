import 'package:dental_lab_app/features/departments/data/models/department_model.dart';

sealed class DepartmentsState {
  const DepartmentsState();
}

class DepartmentsInitial extends DepartmentsState {
  const DepartmentsInitial();
}

class DepartmentsLoading extends DepartmentsState {
  const DepartmentsLoading();
}

class DepartmentsLoaded extends DepartmentsState {
  const DepartmentsLoaded(
    this.departments, {
    this.includeInactive = false,
    this.isBusy = false,
  });

  final List<DepartmentModel> departments;

  /// Whether retired departments are being shown. Kept in the state so a
  /// reload after a save asks for the same set the user was looking at.
  final bool includeInactive;

  /// A write is in flight. Actions disable rather than the list vanishing.
  final bool isBusy;

  DepartmentsLoaded copyWith({
    List<DepartmentModel>? departments,
    bool? includeInactive,
    bool? isBusy,
  }) => DepartmentsLoaded(
    departments ?? this.departments,
    includeInactive: includeInactive ?? this.includeInactive,
    isBusy: isBusy ?? this.isBusy,
  );
}

class DepartmentsError extends DepartmentsState {
  const DepartmentsError(this.message);

  final String message;
}

/// A one-shot message: the cubit emits it, the screen toasts it, and the
/// loaded state comes straight back.
class DepartmentsMessage extends DepartmentsState {
  const DepartmentsMessage(this.message, {this.isError = false});

  final String message;
  final bool isError;
}
