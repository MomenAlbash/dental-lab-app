import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/employees/logic/employee_details/employee_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeeDetailsCubit extends Cubit<EmployeeDetailsState> {
  EmployeeDetailsCubit(this._employeesRepo)
    : super(const EmployeeDetailsInitial());

  final EmployeesRepo _employeesRepo;

  EmployeeModel? _employee;

  Future<void> getEmployee(String id) async {
    emit(const EmployeeDetailsLoading());

    final result = await _employeesRepo.getEmployeeById(id);

    result.fold(
      (failure) => emit(EmployeeDetailsError(failure.errorMessage)),
      (employee) {
        _employee = employee;
        emit(EmployeeDetailsLoaded(employee));
      },
    );
  }

  Future<void> uploadFile(String filePath) async {
    final employee = _employee;
    if (employee == null) return;

    emit(EmployeeDetailsLoaded(employee, isBusy: true));

    final result = await _employeesRepo.uploadEmployeeFile(
      id: employee.id,
      filePath: filePath,
    );

    await result.fold(
      (failure) async {
        emit(EmployeeDetailsActionError(failure.errorMessage));
        emit(EmployeeDetailsLoaded(employee));
      },
      (_) async {
        emit(const EmployeeDetailsActionSuccess('تمت إضافة الملف'));
        await _refresh();
      },
    );
  }

  Future<void> deleteFile(String fileId) async {
    final employee = _employee;
    if (employee == null) return;

    emit(EmployeeDetailsLoaded(employee, isBusy: true));

    final result = await _employeesRepo.deleteEmployeeFile(
      id: employee.id,
      fileId: fileId,
    );

    await result.fold(
      (failure) async {
        emit(EmployeeDetailsActionError(failure.errorMessage));
        emit(EmployeeDetailsLoaded(employee));
      },
      (_) async {
        emit(const EmployeeDetailsActionSuccess('تم حذف الملف'));
        await _refresh();
      },
    );
  }

  /// Re-fetches the employee so the attachments list reflects the latest state.
  Future<void> _refresh() async {
    final employee = _employee;
    if (employee == null) return;

    final result = await _employeesRepo.getEmployeeById(employee.id);

    result.fold((_) => emit(EmployeeDetailsLoaded(employee)), (refreshed) {
      _employee = refreshed;
      emit(EmployeeDetailsLoaded(refreshed));
    });
  }
}
