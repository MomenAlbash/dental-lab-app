import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

/// `InvoiceStatus` — `1 = Unpaid, 2 = PartiallyPaid, 3 = Paid, 4 = Cancelled`.
enum InvoiceStatus {
  unpaid(1),
  partiallyPaid(2),
  paid(3),
  cancelled(4);

  const InvoiceStatus(this.value);
  final int value;

  String get label => switch (this) {
    InvoiceStatus.unpaid => 'غير مدفوعة',
    InvoiceStatus.partiallyPaid => 'مدفوعة جزئياً',
    InvoiceStatus.paid => 'مدفوعة',
    InvoiceStatus.cancelled => 'ملغاة',
  };

  static InvoiceStatus? fromValue(int? value) {
    for (final status in InvoiceStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// `InvoiceLineDto`.
class InvoiceLineModel {
  const InvoiceLineModel({
    required this.id,
    this.description,
    this.quantity = 1,
    this.unitPrice = 0,
  });

  final String id;
  final String? description;
  final int quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;

  factory InvoiceLineModel.fromJson(Map<String, dynamic> json) {
    return InvoiceLineModel(
      id: json['id'] as String,
      description: json['description'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// `InvoiceDto`.
class InvoiceModel {
  const InvoiceModel({
    required this.id,
    this.invoiceNumber,
    required this.laboratoryId,
    required this.doctorId,
    this.doctorName,
    this.caseId,
    this.caseNumber,
    this.currency,
    this.totalAmount = 0,
    this.subtotalAmount = 0,
    this.discountValue = 0,
    this.discountPercentage = 0,
    this.paidAmount = 0,
    this.status,
    this.issuedAt,
    this.dueDate,
    this.lines = const [],
    this.canDelete = false,
    this.deleteMessage,
  });

  final String id;
  final String? invoiceNumber;
  final String laboratoryId;
  final String doctorId;
  final String? doctorName;
  final String? caseId;
  final String? caseNumber;
  final CurrencyModel? currency;
  final double totalAmount;
  final double subtotalAmount;
  final double discountValue;
  final double discountPercentage;
  final double paidAmount;
  final InvoiceStatus? status;
  final DateTime? issuedAt;
  final DateTime? dueDate;
  final List<InvoiceLineModel> lines;

  /// Within five minutes of issue and with no payments against it.
  ///
  /// Deliberately ignores *who* is asking: an admin may delete past the window
  /// anyway, and the server applies that bypass at the point of deletion. The
  /// UI therefore offers the action to an admin regardless of this flag, and
  /// shows [deleteMessage] on the disabled control for everyone else.
  final bool canDelete;

  final String? deleteMessage;

  double get remainingAmount => totalAmount - paidAmount;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? const [];

    return InvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String?,
      laboratoryId: json['laboratoryId'] as String,
      doctorId: json['doctorId'] as String,
      doctorName: json['doctorName'] as String?,
      caseId: json['caseId'] as String?,
      caseNumber: json['caseNumber'] as String?,
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      subtotalAmount: (json['subtotalAmount'] as num?)?.toDouble() ?? 0,
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      status: InvoiceStatus.fromValue(json['status'] as int?),
      issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? ''),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.tryParse(json['dueDate'] as String),
      lines: rawLines
          .whereType<Map<String, dynamic>>()
          .map(InvoiceLineModel.fromJson)
          .toList(),
      canDelete: json['canDelete'] as bool? ?? false,
      deleteMessage: json['deleteMessage'] as String?,
    );
  }
}
