import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

/// `PaymentMethod` — `1 = Cash, 2 = BankTransfer, 3 = ShamCash, 4 = Points`.
enum PaymentMethod {
  cash(1),
  bankTransfer(2),
  shamCash(3),
  points(4);

  const PaymentMethod(this.value);
  final int value;

  String get label => switch (this) {
    PaymentMethod.cash => 'نقداً',
    PaymentMethod.bankTransfer => 'حوالة بنكية',
    PaymentMethod.shamCash => 'شام كاش',
    PaymentMethod.points => 'نقاط',
  };

  static PaymentMethod? fromValue(int? value) {
    for (final method in PaymentMethod.values) {
      if (method.value == value) return method;
    }
    return null;
  }
}

/// `PaymentStatus` — `1 = PendingVerification, 2 = Verified, 3 = Rejected`.
enum PaymentStatus {
  pendingVerification(1),
  verified(2),
  rejected(3);

  const PaymentStatus(this.value);
  final int value;

  String get label => switch (this) {
    PaymentStatus.pendingVerification => 'بانتظار التحقق',
    PaymentStatus.verified => 'موثّقة',
    PaymentStatus.rejected => 'مرفوضة',
  };

  static PaymentStatus? fromValue(int? value) {
    for (final status in PaymentStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// Covers both `PaymentDto` and the leaner `PaymentVerificationDto`
/// (`GET /Accounting/payments/pending`) — the latter carries everything but
/// [invoiceId], [invoiceNumber], [laboratoryId], [verifiedByName] and
/// [verifiedAt], so those stay nullable here instead of this being two
/// near-identical models.
class PaymentModel {
  const PaymentModel({
    required this.id,
    this.invoiceId,
    this.invoiceNumber,
    this.doctorId,
    this.doctorName,
    this.laboratoryId,
    this.currency,
    this.amount = 0,
    this.method,
    this.status,
    this.receiptFilePath,
    this.verifiedByName,
    this.verifiedAt,
    this.notes,
    this.submittedAt,
  });

  final String id;
  final String? invoiceId;
  final String? invoiceNumber;
  final String? doctorId;
  final String? doctorName;
  final String? laboratoryId;
  final CurrencyModel? currency;
  final double amount;
  final PaymentMethod? method;
  final PaymentStatus? status;
  final String? receiptFilePath;
  final String? verifiedByName;
  final DateTime? verifiedAt;
  final String? notes;
  final DateTime? submittedAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      invoiceId: json['invoiceId'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      doctorId: json['doctorId'] as String?,
      doctorName: json['doctorName'] as String?,
      laboratoryId: json['laboratoryId'] as String?,
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      method: PaymentMethod.fromValue(json['method'] as int?),
      status: PaymentStatus.fromValue(json['status'] as int?),
      receiptFilePath: json['receiptFilePath'] as String?,
      verifiedByName: json['verifiedByName'] as String?,
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.tryParse(json['verifiedAt'] as String),
      notes: json['notes'] as String?,
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.tryParse(json['submittedAt'] as String),
    );
  }
}
