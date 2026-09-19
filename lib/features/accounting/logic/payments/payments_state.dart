import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';

sealed class PaymentsState {
  const PaymentsState();
}

class PaymentsInitial extends PaymentsState {
  const PaymentsInitial();
}

class PaymentsLoading extends PaymentsState {
  const PaymentsLoading();
}

class PaymentsLoaded extends PaymentsState {
  const PaymentsLoaded(this.payments);
  final List<PaymentModel> payments;
}

class PaymentsError extends PaymentsState {
  const PaymentsError(this.message);
  final String message;
}

/// A payment was deleted — the list toasts and reloads.
class PaymentDeleted extends PaymentsState {
  const PaymentDeleted();
}

/// The delete was refused. Carries the server's own sentence rather than a
/// generic failure: `Finance:FullAccess` is its rule to enforce.
class PaymentDeleteError extends PaymentsState {
  const PaymentDeleteError(this.message);
  final String message;
}
