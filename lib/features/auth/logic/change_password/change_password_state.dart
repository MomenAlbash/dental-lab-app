sealed class ChangePasswordState {
  const ChangePasswordState();
}

class ChangePasswordInitial extends ChangePasswordState {
  const ChangePasswordInitial();
}

class ChangePasswordSubmitting extends ChangePasswordState {
  const ChangePasswordSubmitting();
}

class ChangePasswordSuccess extends ChangePasswordState {
  const ChangePasswordSuccess();
}

class ChangePasswordError extends ChangePasswordState {
  const ChangePasswordError(this.message);
  final String message;
}
