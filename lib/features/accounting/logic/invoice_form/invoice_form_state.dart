import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/invoice_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';

sealed class InvoiceFormState {
  const InvoiceFormState();
}

class InvoiceFormInitial extends InvoiceFormState {
  const InvoiceFormInitial();
}

class InvoiceFormCatalogLoading extends InvoiceFormState {
  const InvoiceFormCatalogLoading();
}

/// The doctors and currencies the form can offer — loaded once, independent
/// of submission.
class InvoiceFormCatalogLoaded extends InvoiceFormState {
  const InvoiceFormCatalogLoaded({
    required this.doctors,
    required this.currencies,
  });
  final List<DoctorModel> doctors;
  final List<CurrencyModel> currencies;
}

class InvoiceFormCatalogError extends InvoiceFormState {
  const InvoiceFormCatalogError(this.message);
  final String message;
}

class InvoiceFormSubmitting extends InvoiceFormState {
  const InvoiceFormSubmitting();
}

class InvoiceFormSuccess extends InvoiceFormState {
  const InvoiceFormSuccess(this.invoice);
  final InvoiceModel invoice;
}

class InvoiceFormError extends InvoiceFormState {
  const InvoiceFormError(this.message);
  final String message;
}
