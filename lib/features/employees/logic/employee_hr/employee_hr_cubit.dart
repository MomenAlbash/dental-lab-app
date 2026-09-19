import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class EmployeeHrState {
  const EmployeeHrState();
}

class EmployeeHrIdle extends EmployeeHrState {
  const EmployeeHrIdle();
}

class EmployeeHrBusy extends EmployeeHrState {
  const EmployeeHrBusy();
}

/// A write went through and the employee came back changed — the detail
/// screen takes this rather than refetching.
class EmployeeHrSaved extends EmployeeHrState {
  const EmployeeHrSaved(this.employee, this.message);

  final EmployeeModel employee;
  final String message;
}

class EmployeeHrNotesLoaded extends EmployeeHrState {
  const EmployeeHrNotesLoaded(this.notes);
  final List<EmployeeNoteModel> notes;
}

class EmployeeHrError extends EmployeeHrState {
  const EmployeeHrError(this.message);
  final String message;
}

/// The employment side of an employee: their photo, whether they still work
/// here, and the notes on their file.
///
/// Separate from the profile cubit because these are not edits to a form —
/// each is its own act with its own consequence, and terminating somebody is
/// not the same kind of thing as correcting their phone number.
class EmployeeHrCubit extends Cubit<EmployeeHrState> {
  EmployeeHrCubit(this._repo) : super(const EmployeeHrIdle());

  final EmployeesRepo _repo;

  Future<void> uploadImage({
    required String employeeId,
    required String filePath,
  }) => _write(
    'تم تحديث الصورة',
    () => _repo.uploadImage(id: employeeId, filePath: filePath),
  );

  /// Ends the employment, dated. The person stays — see the repo's note on
  /// why terminating is not deleting.
  Future<void> terminate({
    required String employeeId,
    required DateTime terminationDate,
    String? note,
  }) => _write(
    'تم إنهاء عمل الموظف',
    () => _repo.terminate(
      id: employeeId,
      terminationDate: terminationDate,
      note: note,
    ),
  );

  Future<void> reinstate(String employeeId) =>
      _write('تمت إعادة تعيين الموظف', () => _repo.reinstate(employeeId));

  Future<void> loadNotes(String employeeId) async {
    emit(const EmployeeHrBusy());

    final result = await _repo.getNotes(employeeId: employeeId);
    if (isClosed) return;

    result.fold(
      (failure) => emit(EmployeeHrError(failure.errorMessage)),
      (notes) => emit(EmployeeHrNotesLoaded(notes)),
    );
  }

  Future<void> addNote({
    required String employeeId,
    required String note,
  }) async {
    final result = await _repo.addNote(employeeId: employeeId, note: note);
    if (isClosed) return;

    await result.fold(
      (failure) async => emit(EmployeeHrError(failure.errorMessage)),
      (_) async => loadNotes(employeeId),
    );
  }

  Future<void> deleteNote({
    required String employeeId,
    required String noteId,
  }) async {
    final result = await _repo.deleteNote(noteId);
    if (isClosed) return;

    await result.fold(
      (failure) async => emit(EmployeeHrError(failure.errorMessage)),
      (_) async => loadNotes(employeeId),
    );
  }

  Future<void> _write(
    String successMessage,
    Future<Either<Failure, EmployeeModel>> Function() request,
  ) async {
    emit(const EmployeeHrBusy());

    final result = await request();
    if (isClosed) return;

    result.fold(
      (failure) => emit(EmployeeHrError(failure.errorMessage)),
      (employee) => emit(EmployeeHrSaved(employee, successMessage)),
    );
  }
}
