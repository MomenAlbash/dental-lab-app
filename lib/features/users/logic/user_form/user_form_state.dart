import 'package:dental_lab_app/features/users/data/models/user_model.dart';

sealed class UserFormState {
  const UserFormState();
}

class UserFormInitial extends UserFormState {
  const UserFormInitial();
}

class UserFormSubmitting extends UserFormState {
  const UserFormSubmitting();
}

class UserFormSuccess extends UserFormState {
  const UserFormSuccess(this.user);
  final UserModel user;
}

class UserFormError extends UserFormState {
  const UserFormError(this.message);
  final String message;
}
