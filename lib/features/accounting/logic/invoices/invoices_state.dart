import 'package:dental_lab_app/features/accounting/data/models/invoice_model.dart';

sealed class InvoicesState {
  const InvoicesState();
}

class InvoicesInitial extends InvoicesState {
  const InvoicesInitial();
}

class InvoicesLoading extends InvoicesState {
  const InvoicesLoading();
}

class InvoicesLoaded extends InvoicesState {
  const InvoicesLoaded(this.invoices);
  final List<InvoiceModel> invoices;
}

class InvoicesError extends InvoicesState {
  const InvoicesError(this.message);
  final String message;
}
