import 'package:dental_lab_app/features/roles/data/models/role_model.dart';

sealed class RolesState {
  const RolesState();
}

class RolesInitial extends RolesState {
  const RolesInitial();
}

class RolesLoading extends RolesState {
  const RolesLoading();
}

class RolesLoaded extends RolesState {
  const RolesLoaded(this.roles);
  final List<RoleModel> roles;
}

class RolesError extends RolesState {
  const RolesError(this.message);
  final String message;
}
