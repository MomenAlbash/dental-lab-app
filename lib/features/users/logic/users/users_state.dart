import 'package:dental_lab_app/features/users/data/models/user_model.dart';

sealed class UsersState {
  const UsersState();
}

class UsersInitial extends UsersState {
  const UsersInitial();
}

class UsersLoading extends UsersState {
  const UsersLoading();
}

class UsersLoaded extends UsersState {
  const UsersLoaded(this.users);
  final List<UserModel> users;
}

class UsersError extends UsersState {
  const UsersError(this.message);
  final String message;
}

class UserDeleted extends UsersState {
  const UserDeleted();
}

class UserDeleteError extends UsersState {
  const UserDeleteError(this.message);
  final String message;
}
