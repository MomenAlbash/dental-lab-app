/// `CreateInvoiceLineRequest`.
class CreateInvoiceLineRequestModel {
  const CreateInvoiceLineRequestModel({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
  });

  final String description;
  final int quantity;
  final double unitPrice;

  Map<String, dynamic> toJson() => {
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
}

/// `CreateInvoiceRequest` — a manual, ad-hoc invoice not tied to a case
/// (`POST /Accounting/invoices`). A case's own invoice is generated instead
/// through `POST /Accounting/invoices/from-case/{caseId}`.
class CreateInvoiceRequestModel {
  const CreateInvoiceRequestModel({
    required this.doctorId,
    this.caseId,
    this.currencyId,
    this.dueDate,
    this.discountValue,
    this.discountPercentage,
    this.lines = const [],
  });

  final String doctorId;
  final String? caseId;
  final String? currencyId;

  /// ISO 8601.
  final String? dueDate;
  final double? discountValue;
  final double? discountPercentage;
  final List<CreateInvoiceLineRequestModel> lines;

  Map<String, dynamic> toJson() => {
    'doctorId': doctorId,
    'caseId': caseId,
    'currencyId': currencyId,
    'dueDate': dueDate,
    'discountValue': discountValue,
    'discountPercentage': discountPercentage,
    'lines': lines.map((l) => l.toJson()).toList(),
  };
}
