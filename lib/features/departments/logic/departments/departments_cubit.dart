import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/departments/data/models/department_model.dart';
import 'package:dental_lab_app/features/departments/data/models/save_department_request_model.dart';
import 'package:dental_lab_app/features/departments/data/repos/departments_repo.dart';
import 'package:dental_lab_app/features/departments/logic/departments/departments_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the laboratory's departments and the restoration stages they own.
class DepartmentsCubit extends Cubit<DepartmentsState> {
  DepartmentsCubit(this._repo) : super(const DepartmentsInitial());

  final DepartmentsRepo _repo;

  bool _includeInactive = false;

  /// Kept so a failed write can put the list back rather than replacing a
  /// working screen with an error.
  List<DepartmentModel> _lastLoaded = const [];

  Future<void> load({bool? includeInactive}) async {
    _includeInactive = includeInactive ?? _includeInactive;
    emit(const DepartmentsLoading());

    final result = await _repo.getDepartments(
      includeInactive: _includeInactive,
    );
    if (isClosed) return;

    result.fold((failure) => emit(DepartmentsError(failure.errorMessage)), (
      departments,
    ) {
      _lastLoaded = _sorted(departments);
      emit(DepartmentsLoaded(_lastLoaded, includeInactive: _includeInactive));
    });
  }

  /// Stage id → another department that also works it, skipping [exclude].
  ///
  /// Stages and departments are many-to-many on the server (a
  /// `WorkflowStageDepartment` join table), so this is context for the picker,
  /// never a rule: knowing "الصب works this too" changes how a lab splits the
  /// work, but sharing a stage is legitimate.
  Map<String, String> stageOwners({String? exclude}) {
    final owners = <String, String>{};

    for (final department in _lastLoaded) {
      if (department.id == exclude) continue;
      for (final stage in department.stages) {
        owners[stage.id] = department.displayName;
      }
    }

    return owners;
  }

  Future<void> createDepartment(SaveDepartmentRequestModel body) =>
      _run('تمت إضافة القسم', () => _repo.createDepartment(body));

  Future<void> updateDepartment({
    required String id,
    required SaveDepartmentRequestModel body,
  }) =>
      _run('تم تعديل القسم', () => _repo.updateDepartment(id: id, body: body));

  /// Replaces the stages a department owns, leaving everything else alone.
  ///
  /// The save endpoint takes the whole department, so the current name and
  /// people are resent unchanged — otherwise linking a stage would blank the
  /// description and empty the department of its staff.
  Future<void> setStages({
    required DepartmentModel department,
    required List<String> stageIds,
  }) => _run(
    'تم تحديث مراحل القسم',
    () => _repo.updateDepartment(
      id: department.id,
      body: SaveDepartmentRequestModel(
        name: department.name?.trim().isNotEmpty ?? false
            ? department.name!
            : department.displayName,
        nameAr: department.nameAr,
        description: department.description,
        isActive: department.isActive,
        parentId: department.parentId,
        stageIds: stageIds,
        employeeIds: [
          for (final employee in department.employees) ?employee.employeeId,
        ],
      ),
    ),
  );

  Future<void> deleteDepartment(String id) =>
      _run('تم حذف القسم', () => _repo.deleteDepartment(id));

  Future<void> _run<T>(
    String successMessage,
    Future<Either<Failure, T>> Function() action,
  ) async {
    final current = state;
    if (current is DepartmentsLoaded) emit(current.copyWith(isBusy: true));

    final result = await action();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(DepartmentsMessage(failure.errorMessage, isError: true));
        emit(DepartmentsLoaded(_lastLoaded, includeInactive: _includeInactive));
      },
      (_) async {
        emit(DepartmentsMessage(successMessage));
        await load();
      },
    );
  }

  /// Active first, then by name: a retired department is reference material,
  /// not something the user is looking for.
  static List<DepartmentModel> _sorted(List<DepartmentModel> departments) {
    final sorted = [...departments];
    sorted.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.displayName.compareTo(b.displayName);
    });
    return sorted;
  }
}
