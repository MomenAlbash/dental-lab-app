import 'package:dental_lab_app/features/auth/data/repos/login_repo.dart';
import 'package:dental_lab_app/features/auth/logic/change_password/change_password_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit(this._loginRepo) : super(const ChangePasswordInitial());

  final LoginRepo _loginRepo;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(const ChangePasswordSubmitting());

    final result = await _loginRepo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    result.fold(
      (failure) => emit(ChangePasswordError(failure.errorMessage)),
      (_) => emit(const ChangePasswordSuccess()),
    );
  }
}
