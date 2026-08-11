import 'package:dental_lab_app/features/users/data/models/user_filters_model.dart';
import 'package:dental_lab_app/features/users/data/repos/users_repo.dart';
import 'package:dental_lab_app/features/users/logic/users/users_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// `GET /Users` supports server-side filtering (`laboratoryId`, `doctorId`,
/// `employeeId` query params), so — unlike [DoctorsCubit], which filters
/// client-side — applying filters here re-fetches from the API.
class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._usersRepo) : super(const UsersInitial());

  final UsersRepo _usersRepo;

  UserFiltersModel _filters = UserFiltersModel.empty;

  UserFiltersModel get filters => _filters;

  Future<void> getUsers() async {
    emit(const UsersLoading());

    final result = await _usersRepo.getUsers(filters: _filters);

    result.fold(
      (failure) => emit(UsersError(failure.errorMessage)),
      (users) => emit(UsersLoaded(users)),
    );
  }

  /// Replaces the active filters and reloads the list.
  Future<void> applyFilters(UserFiltersModel filters) async {
    _filters = filters;
    await getUsers();
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
