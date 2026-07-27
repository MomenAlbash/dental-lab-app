import 'package:dental_lab_app/features/auth/data/models/login_request_model.dart';
import 'package:dental_lab_app/features/auth/data/repos/login_repo.dart';
import 'package:dental_lab_app/features/auth/logic/login/login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._loginRepo) : super(const LoginInitial());

  final LoginRepo _loginRepo;

  Future<void> login(LoginRequestModel loginRequestBody) async {
    emit(const LoginLoading());

    final result = await _loginRepo.login(loginRequestBody);

    result.fold(
      (failure) => emit(LoginError(failure.errorMessage)),
      (_) => emit(const LoginSuccess()),
    );
  }
}
