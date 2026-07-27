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
}
