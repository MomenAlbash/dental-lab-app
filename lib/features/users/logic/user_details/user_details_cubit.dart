import 'package:dental_lab_app/features/users/data/models/update_user_request_model.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/data/repos/users_repo.dart';
import 'package:dental_lab_app/features/users/logic/user_details/user_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserDetailsCubit extends Cubit<UserDetailsState> {
  UserDetailsCubit(this._usersRepo) : super(const UserDetailsInitial());

  final UsersRepo _usersRepo;

  UserModel? _user;

  Future<void> getUser(String id) async {
    emit(const UserDetailsLoading());

    final result = await _usersRepo.getUserById(id);

    result.fold((failure) => emit(UserDetailsError(failure.errorMessage)), (
      user,
    ) {
      _user = user;
      emit(UserDetailsLoaded(user));
    });
  }

  Future<void> saveChanges({
    required String? email,
    required String? roleId,
    required bool isAdmin,
    required bool isActive,
  }) async {
    final user = _user;
    if (user == null) return;

    emit(UserDetailsLoaded(user, isBusy: true));

    final result = await _usersRepo.updateUser(
      id: user.id,
      updateUserRequestBody: UpdateUserRequestModel(
        email: email,
        roleId: roleId,
        isAdmin: isAdmin,
        isActive: isActive,
      ),
    );

    result.fold(
      (failure) {
        emit(UserDetailsActionError(failure.errorMessage));
        emit(UserDetailsLoaded(user));
      },
      (updated) {
        _user = updated;
        emit(const UserDetailsActionSuccess('تم حفظ التعديلات'));
        emit(UserDetailsLoaded(updated));
      },
    );
  }

  Future<void> toggleActive() async {
    final user = _user;
    if (user == null) return;

    emit(UserDetailsLoaded(user, isBusy: true));

    final result = await _usersRepo.setUserActive(
      id: user.id,
      isActive: !user.isActive,
    );

    await result.fold(
      (failure) async {
        emit(UserDetailsActionError(failure.errorMessage));
        emit(UserDetailsLoaded(user));
      },
      (_) async {
        emit(
          UserDetailsActionSuccess(
            user.isActive ? 'تم إيقاف المستخدم' : 'تم تفعيل المستخدم',
          ),
        );
        await _refresh();
      },
    );
  }

  Future<void> resetPassword(String newPassword) async {
    final user = _user;
    if (user == null) return;

    emit(UserDetailsLoaded(user, isBusy: true));

    final result = await _usersRepo.resetPassword(
      id: user.id,
      newPassword: newPassword,
    );

    result.fold(
      (failure) {
        emit(UserDetailsActionError(failure.errorMessage));
        emit(UserDetailsLoaded(user));
      },
      (_) {
        emit(const UserDetailsActionSuccess('تم تغيير كلمة المرور'));
        emit(UserDetailsLoaded(user));
      },
    );
  }

  Future<void> _refresh() async {
    final user = _user;
    if (user == null) return;

    final result = await _usersRepo.getUserById(user.id);

    result.fold((_) => emit(UserDetailsLoaded(user)), (refreshed) {
      _user = refreshed;
      emit(UserDetailsLoaded(refreshed));
    });
  }
}
