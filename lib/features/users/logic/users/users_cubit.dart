import 'package:dental_lab_app/features/users/data/repos/users_repo.dart';
import 'package:dental_lab_app/features/users/logic/users/users_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._usersRepo) : super(const UsersInitial());

  final UsersRepo _usersRepo;

  Future<void> getUsers() async {
    emit(const UsersLoading());

    final result = await _usersRepo.getUsers();

    result.fold(
      (failure) => emit(UsersError(failure.errorMessage)),
      (users) => emit(UsersLoaded(users)),
    );
  }

  Future<void> deleteUser(String id) async {
    final result = await _usersRepo.deleteUser(id);

    await result.fold(
      (failure) async => emit(UserDeleteError(failure.errorMessage)),
      (_) async {
        emit(const UserDeleted());
        await getUsers();
      },
    );
  }
}
