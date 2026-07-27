import 'package:dental_lab_app/features/users/data/models/user_model.dart';

sealed class UserDetailsState {
  const UserDetailsState();
}

class UserDetailsInitial extends UserDetailsState {
  const UserDetailsInitial();
}

class UserDetailsLoading extends UserDetailsState {
  const UserDetailsLoading();
}

class UserDetailsLoaded extends UserDetailsState {
  const UserDetailsLoaded(this.user, {this.isBusy = false});

  final UserModel user;

  /// True while a save / activate / reset action is in flight.
  final bool isBusy;
}

class UserDetailsError extends UserDetailsState {
  const UserDetailsError(this.message);
  final String message;
}

/// Transient failure of an action — surfaced as a toast.
class UserDetailsActionError extends UserDetailsState {
  const UserDetailsActionError(this.message);
  final String message;
}

/// Transient success of an action — surfaced as a toast.
class UserDetailsActionSuccess extends UserDetailsState {
  const UserDetailsActionSuccess(this.message);
  final String message;
}
