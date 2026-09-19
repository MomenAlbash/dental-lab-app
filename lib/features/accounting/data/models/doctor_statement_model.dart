import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

/// `StatementEntryDto` — one line of the ledger: either a debit (an invoice)
/// or a credit (a payment), never both.
class StatementEntryModel {
  const StatementEntryModel({
    required this.date,
    this.description,
    this.reference,
    this.caseNumber,
    this.debit,
    this.credit,
    this.runningBalance = 0,
  });

  final DateTime date;
  final String? description;
  final String? reference;
  final String? caseNumber;
  final double? debit;
  final double? credit;
  final double runningBalance;

  factory StatementEntryModel.fromJson(Map<String, dynamic> json) {
    return StatementEntryModel(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      description: json['description'] as String?,
      reference: json['reference'] as String?,
      caseNumber: json['caseNumber'] as String?,
      debit: (json['debit'] as num?)?.toDouble(),
      credit: (json['credit'] as num?)?.toDouble(),
      runningBalance: (json['runningBalance'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// `CurrencyStatementDto` — the doctor's ledger in one currency.
class CurrencyStatementModel {
  const CurrencyStatementModel({
    this.currency,
    this.from,
    this.to,
    this.openingBalance = 0,
    this.totalInvoiced = 0,
    this.totalPaid = 0,
    this.closingBalance = 0,
    this.invoiceCount = 0,
    this.paymentCount = 0,
    this.entries = const [],
  });

  final CurrencyModel? currency;
  final DateTime? from;
  final DateTime? to;
  final double openingBalance;
  final double totalInvoiced;
  final double totalPaid;
  final double closingBalance;
  final int invoiceCount;
  final int paymentCount;
  final List<StatementEntryModel> entries;

  factory CurrencyStatementModel.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? const [];

    return CurrencyStatementModel(
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      from: json['from'] == null
          ? null
          : DateTime.tryParse(json['from'] as String),
      to: json['to'] == null ? null : DateTime.tryParse(json['to'] as String),
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
      totalInvoiced: (json['totalInvoiced'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      closingBalance: (json['closingBalance'] as num?)?.toDouble() ?? 0,
      invoiceCount: json['invoiceCount'] as int? ?? 0,
      paymentCount: json['paymentCount'] as int? ?? 0,
      entries: rawEntries
          .whereType<Map<String, dynamic>>()
          .map(StatementEntryModel.fromJson)
          .toList(),
    );
  }
}

/// `DoctorStatementDto`.
class DoctorStatementModel {
  const DoctorStatementModel({
    required this.doctorId,
    this.doctorName,
    this.currencies = const [],
  });

  final String doctorId;
  final String? doctorName;
  final List<CurrencyStatementModel> currencies;

  factory DoctorStatementModel.fromJson(Map<String, dynamic> json) {
    final rawCurrencies = json['currencies'] as List<dynamic>? ?? const [];

    return DoctorStatementModel(
      doctorId: json['doctorId'] as String,
      doctorName: json['doctorName'] as String?,
      currencies: rawCurrencies
          .whereType<Map<String, dynamic>>()
          .map(CurrencyStatementModel.fromJson)
          .toList(),
    );
  }
}
