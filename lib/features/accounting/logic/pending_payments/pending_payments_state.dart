import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';

sealed class PendingPaymentsState {
  const PendingPaymentsState();
}

class PendingPaymentsInitial extends PendingPaymentsState {
  const PendingPaymentsInitial();
}

class PendingPaymentsLoading extends PendingPaymentsState {
  const PendingPaymentsLoading();
}

class PendingPaymentsLoaded extends PendingPaymentsState {
  const PendingPaymentsLoaded(this.payments, {this.isBusy = false});
  final List<PaymentModel> payments;

  /// True while a verify/reject call is in flight.
  final bool isBusy;
}

class PendingPaymentsError extends PendingPaymentsState {
  const PendingPaymentsError(this.message);
  final String message;
}

/// Transient failure of a verify/reject — surfaced as a toast.
class PendingPaymentsActionError extends PendingPaymentsState {
  const PendingPaymentsActionError(this.message);
  final String message;
}
