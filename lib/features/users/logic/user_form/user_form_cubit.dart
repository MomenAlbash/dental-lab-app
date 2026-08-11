import 'package:dental_lab_app/features/users/data/models/create_user_request_model.dart';
import 'package:dental_lab_app/features/users/data/repos/users_repo.dart';
import 'package:dental_lab_app/features/users/logic/user_form/user_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserFormCubit extends Cubit<UserFormState> {
  UserFormCubit(this._usersRepo) : super(const UserFormInitial());

  final UsersRepo _usersRepo;

  Future<void> createUser(CreateUserRequestModel createUserRequestBody) async {
    emit(const UserFormSubmitting());

    final result = await _usersRepo.createUser(createUserRequestBody);

    result.fold(
      (failure) => emit(UserFormError(failure.errorMessage)),
      (user) => emit(UserFormSuccess(user)),
    );
  }
}
