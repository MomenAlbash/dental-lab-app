import 'package:dental_lab_app/features/roles/data/repos/roles_repo.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RolesCubit extends Cubit<RolesState> {
  RolesCubit(this._rolesRepo) : super(const RolesInitial());

  final RolesRepo _rolesRepo;

  Future<void> getRoles() async {
    emit(const RolesLoading());

    final result = await _rolesRepo.getRoles();

    result.fold(
      (failure) => emit(RolesError(failure.errorMessage)),
      (roles) => emit(RolesLoaded(roles)),
    );
  }

  /// Removes the role optimistically — the confirm dialog already asked
  /// once, so the row should not also sit there mid-delete. Rolled back
  /// (with a toast, via [RolesActionError]) if the server call fails.
  Future<void> deleteRole(String id) async {
    final state = this.state;
    if (state is! RolesLoaded) return;

    final previous = state.roles;
    emit(
      RolesLoaded([
        for (final r in previous)
          if (r.id != id) r,
      ]),
    );

    final result = await _rolesRepo.deleteRole(id);

    result.fold((failure) {
      emit(RolesLoaded(previous));
      emit(RolesActionError(failure.errorMessage));
    }, (_) {});
  }
}
