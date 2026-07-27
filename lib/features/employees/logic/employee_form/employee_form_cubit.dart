import 'package:dental_lab_app/features/employees/data/models/create_employee_request_model.dart';
import 'package:dental_lab_app/features/employees/data/models/update_employee_request_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/employees/logic/employee_form/employee_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeeFormCubit extends Cubit<EmployeeFormState> {
  EmployeeFormCubit(this._employeesRepo) : super(const EmployeeFormInitial());

  final EmployeesRepo _employeesRepo;

  Future<void> createEmployee(
    CreateEmployeeRequestModel createEmployeeRequestBody,
  ) async {
    emit(const EmployeeFormSubmitting());

    final result = await _employeesRepo.createEmployee(
      createEmployeeRequestBody,
    );

    result.fold(
      (failure) => emit(EmployeeFormError(failure.errorMessage)),
      (employee) => emit(EmployeeFormSuccess(employee)),
    );
  }

  Future<void> updateEmployee({
    required String id,
    required UpdateEmployeeRequestModel updateEmployeeRequestBody,
  }) async {
    emit(const EmployeeFormSubmitting());

    final result = await _employeesRepo.updateEmployee(
      id: id,
      updateEmployeeRequestBody: updateEmployeeRequestBody,
    );

    result.fold(
      (failure) => emit(EmployeeFormError(failure.errorMessage)),
      (employee) => emit(EmployeeFormSuccess(employee)),
    );
  }
}
