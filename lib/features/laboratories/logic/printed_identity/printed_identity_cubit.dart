import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/laboratories/data/models/footer_contact_model.dart';
import 'package:dental_lab_app/features/laboratories/data/repos/laboratories_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class PrintedIdentityState {
  const PrintedIdentityState();
}

class PrintedIdentityIdle extends PrintedIdentityState {
  const PrintedIdentityIdle();
}

class PrintedIdentityBusy extends PrintedIdentityState {
  const PrintedIdentityBusy();
}

class PrintedIdentitySuccess extends PrintedIdentityState {
  const PrintedIdentitySuccess(this.message);
  final String message;
}

class PrintedIdentityError extends PrintedIdentityState {
  const PrintedIdentityError(this.message);
  final String message;
}

/// What the laboratory looks like on paper: its logo and the contact lines
/// printed at the foot of reports and invoices.
///
/// Separate from the laboratory form because it is separate on the server too
/// — three endpoints rather than fields on the record — and because a person
/// fixing a printed phone number has no business also being able to rename the
/// laboratory.
class PrintedIdentityCubit extends Cubit<PrintedIdentityState> {
  PrintedIdentityCubit(this._repo) : super(const PrintedIdentityIdle());

  final LaboratoriesRepo _repo;

  /// Replaces the whole list. A row left out is deleted — that is what makes
  /// reordering and removing possible in one save.
  Future<void> saveContacts({
    required String laboratoryId,
    required List<SaveFooterContactModel> contacts,
  }) => _write(
    'تم حفظ بيانات التذييل',
    () => _repo.setFooterContacts(id: laboratoryId, contacts: contacts),
  );

  Future<void> uploadLogo({
    required String laboratoryId,
    required String filePath,
  }) => _write(
    'تم تحديث الشعار',
    () => _repo.uploadLogo(id: laboratoryId, filePath: filePath),
  );

  /// Back to no logo at all — not the same as uploading a blank one, since
  /// reports lay out differently with no logo than with an empty box.
  Future<void> deleteLogo(String laboratoryId) =>
      _write('تم حذف الشعار', () => _repo.deleteLogo(laboratoryId));

  Future<void> _write<T>(
    String successMessage,
    Future<Either<Failure, T>> Function() request,
  ) async {
    emit(const PrintedIdentityBusy());

    final result = await request();
    if (isClosed) return;

    result.fold(
      (failure) => emit(PrintedIdentityError(failure.errorMessage)),
      (_) => emit(PrintedIdentitySuccess(successMessage)),
    );
  }
}
