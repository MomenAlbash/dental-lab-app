import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeesCubit extends Cubit<EmployeesState> {
  EmployeesCubit(this._employeesRepo) : super(const EmployeesInitial());

  final EmployeesRepo _employeesRepo;

  Future<void> getEmployees() async {
    emit(const EmployeesLoading());

    final result = await _employeesRepo.getEmployees();

    result.fold(
      (failure) => emit(EmployeesError(failure.errorMessage)),
      (employees) => emit(EmployeesLoaded(employees)),
    );
  }

  Future<void> deleteEmployee(String id) async {
    final result = await _employeesRepo.deleteEmployee(id);

    await result.fold(
      (failure) async => emit(EmployeeDeleteError(failure.errorMessage)),
      (_) async {
        emit(const EmployeeDeleted());
        await getEmployees();
      },
    );
  }
}
