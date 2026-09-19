import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/features/roles/data/models/role_model.dart';

sealed class RoleFormState {
  const RoleFormState();
}

class RoleFormInitial extends RoleFormState {
  const RoleFormInitial();
}

class RoleFormCatalogLoading extends RoleFormState {
  const RoleFormCatalogLoading();
}

/// The modules this app can offer as checkboxes — not the same as the
/// user's own permissions, and loaded once, independent of submission.
class RoleFormCatalogLoaded extends RoleFormState {
  const RoleFormCatalogLoaded(this.catalog);
  final List<PermissionName> catalog;
}

class RoleFormCatalogError extends RoleFormState {
  const RoleFormCatalogError(this.message);
  final String message;
}

class RoleFormSubmitting extends RoleFormState {
  const RoleFormSubmitting();
}

class RoleFormSuccess extends RoleFormState {
  const RoleFormSuccess(this.role);
  final RoleModel role;
}

class RoleFormError extends RoleFormState {
  const RoleFormError(this.message);
  final String message;
}
