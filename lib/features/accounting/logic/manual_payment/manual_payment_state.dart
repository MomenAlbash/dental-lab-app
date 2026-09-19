import 'package:dental_lab_app/features/accounting/data/models/invoice_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';

sealed class ManualPaymentState {
  const ManualPaymentState();
}

class ManualPaymentInitial extends ManualPaymentState {
  const ManualPaymentInitial();
}

/// The chosen doctor's own invoices — fetched fresh each time the doctor
/// changes, since a payment must be filed against one of *their* invoices.
class ManualPaymentInvoicesLoading extends ManualPaymentState {
  const ManualPaymentInvoicesLoading();
}

class ManualPaymentInvoicesLoaded extends ManualPaymentState {
  const ManualPaymentInvoicesLoaded(this.invoices);
  final List<InvoiceModel> invoices;
}

class ManualPaymentInvoicesError extends ManualPaymentState {
  const ManualPaymentInvoicesError(this.message);
  final String message;
}

class ManualPaymentSubmitting extends ManualPaymentState {
  const ManualPaymentSubmitting();
}

class ManualPaymentSuccess extends ManualPaymentState {
  const ManualPaymentSuccess(this.payment);
  final PaymentModel payment;
}

class ManualPaymentError extends ManualPaymentState {
  const ManualPaymentError(this.message);
  final String message;
}
