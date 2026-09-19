import 'package:dental_lab_app/features/roles/data/models/create_role_request_model.dart';
import 'package:dental_lab_app/features/roles/data/models/role_model.dart';
import 'package:dental_lab_app/features/roles/data/models/update_role_request_model.dart';
import 'package:dental_lab_app/features/roles/data/repos/roles_repo.dart';
import 'package:dental_lab_app/features/roles/logic/role_form/role_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoleFormCubit extends Cubit<RoleFormState> {
  RoleFormCubit(this._repo) : super(const RoleFormInitial());

  final RolesRepo _repo;

  Future<void> loadPermissionCatalog() async {
    emit(const RoleFormCatalogLoading());

    final result = await _repo.getRolePermissionCatalog();

    result.fold(
      (failure) => emit(RoleFormCatalogError(failure.errorMessage)),
      (catalog) => emit(RoleFormCatalogLoaded(catalog)),
    );
  }

  Future<void> createRole(CreateRoleRequestModel requestBody) async {
    emit(const RoleFormSubmitting());

    final result = await _repo.createRole(requestBody);

    result.fold(
      (failure) => emit(RoleFormError(failure.errorMessage)),
      (role) => emit(RoleFormSuccess(role)),
    );
  }

  Future<void> updateRole({
    required String id,
    required UpdateRoleRequestModel updateRequestBody,
    required List<RolePermission> permissions,
  }) async {
    emit(const RoleFormSubmitting());

    final result = await _repo.updateRole(
      id: id,
      updateRequestBody: updateRequestBody,
      permissions: permissions,
    );

    result.fold(
      (failure) => emit(RoleFormError(failure.errorMessage)),
      (role) => emit(RoleFormSuccess(role)),
    );
  }
}
