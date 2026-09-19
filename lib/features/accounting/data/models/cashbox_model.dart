import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

/// Where a ledger line came from (`CashBoxEntrySource`).
///
/// Only a [manual] line can be deleted here — a payment or an expense line is
/// read-only in the box and is managed from its own screen, which is why the
/// row offers no action for those two rather than offering one that fails.
enum CashBoxEntrySource {
  payment(1, 'دفعة'),
  expense(2, 'مصروف'),
  manual(3, 'حركة يدوية');

  const CashBoxEntrySource(this.value, this.label);

  final int value;
  final String label;

  bool get isManual => this == CashBoxEntrySource.manual;

  static CashBoxEntrySource? fromValue(int? value) {
    for (final source in CashBoxEntrySource.values) {
      if (source.value == value) return source;
    }
    return null;
  }
}

/// Which way the cash moved (`CashBoxEntryType`).
enum CashBoxEntryType {
  cashIn(1, 'إيداع'),
  cashOut(2, 'سحب');

  const CashBoxEntryType(this.value, this.label);

  final int value;
  final String label;

  static CashBoxEntryType? fromValue(int? value) {
    for (final type in CashBoxEntryType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// One line of the box's ledger (`CashBoxLedgerEntryDto`), in chronological
/// order with the balance after it.
class CashBoxLedgerEntryModel {
  const CashBoxLedgerEntryModel({
    this.date,
    this.description,
    this.reference,
    this.source,
    this.entryId,
    this.moneyIn,
    this.moneyOut,
    this.runningBalance = 0,
    this.canDelete = false,
    this.deleteMessage,
  });

  final DateTime? date;
  final String? description;
  final String? reference;
  final CashBoxEntrySource? source;

  /// Present only on a manual line — the id the delete would name. A payment
  /// or expense line has none, which is the server saying "not from here".
  final String? entryId;

  /// Exactly one of the two is set on any line.
  final double? moneyIn;
  final double? moneyOut;

  final double runningBalance;

  /// Within the entry's first five minutes. An admin may delete at any time
  /// regardless of what this says — the server applies that bypass at the
  /// point of deletion rather than reflecting it here.
  final bool canDelete;

  /// Why the delete is refused, shown on the disabled control rather than
  /// hiding it: an action that vanishes teaches nobody the rule.
  final String? deleteMessage;

  bool get isManual => source?.isManual ?? false;

  factory CashBoxLedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return CashBoxLedgerEntryModel(
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      description: json['description'] as String?,
      reference: json['reference'] as String?,
      source: CashBoxEntrySource.fromValue(json['source'] as int?),
      entryId: json['entryId'] as String?,
      moneyIn: (json['in'] as num?)?.toDouble(),
      moneyOut: (json['out'] as num?)?.toDouble(),
      runningBalance: (json['runningBalance'] as num?)?.toDouble() ?? 0,
      canDelete: json['canDelete'] as bool? ?? false,
      deleteMessage: json['deleteMessage'] as String?,
    );
  }
}

/// The box's running balance in **one** currency
/// (`CashBoxCurrencyLedgerDto`).
///
/// One of these per currency the lab deals in, never blended: an opening
/// balance in dollars and one in lira are two boxes that happen to sit in the
/// same drawer, and adding them produces a number that is true of nothing.
class CashBoxLedgerModel {
  const CashBoxLedgerModel({
    this.currency,
    this.from,
    this.to,
    this.openingBalance = 0,
    this.totalIn = 0,
    this.totalOut = 0,
    this.closingBalance = 0,
    this.entries = const [],
  });

  final CurrencyModel? currency;
  final DateTime? from;
  final DateTime? to;
  final double openingBalance;
  final double totalIn;
  final double totalOut;
  final double closingBalance;
  final List<CashBoxLedgerEntryModel> entries;

  /// The currency's own formatting, falling back to a bare number only when
  /// the server sent no currency at all.
  String format(double amount) =>
      currency?.format(amount) ?? amount.toStringAsFixed(2);

  factory CashBoxLedgerModel.fromJson(Map<String, dynamic> json) {
    return CashBoxLedgerModel(
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      from: DateTime.tryParse(json['from'] as String? ?? ''),
      to: DateTime.tryParse(json['to'] as String? ?? ''),
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
      totalIn: (json['totalIn'] as num?)?.toDouble() ?? 0,
      totalOut: (json['totalOut'] as num?)?.toDouble() ?? 0,
      closingBalance: (json['closingBalance'] as num?)?.toDouble() ?? 0,
      entries: [
        for (final entry in json['entries'] as List<dynamic>? ?? const [])
          CashBoxLedgerEntryModel.fromJson(entry as Map<String, dynamic>),
      ],
    );
  }
}

/// What the box held before the ledger starts, per currency
/// (`CashBoxOpeningBalanceDto`).
class CashBoxOpeningBalanceModel {
  const CashBoxOpeningBalanceModel({
    required this.currencyId,
    this.currency,
    this.amount = 0,
    this.asOfDate,
    this.setByName,
  });

  final String currencyId;
  final CurrencyModel? currency;
  final double amount;
  final DateTime? asOfDate;
  final String? setByName;

  factory CashBoxOpeningBalanceModel.fromJson(Map<String, dynamic> json) {
    return CashBoxOpeningBalanceModel(
      currencyId: json['currencyId'] as String? ?? '',
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      asOfDate: DateTime.tryParse(json['asOfDate'] as String? ?? ''),
      setByName: json['setByName'] as String?,
    );
  }
}

/// `CreateCashBoxEntryRequest` — a manual cash movement.
class CreateCashBoxEntryRequestModel {
  const CreateCashBoxEntryRequestModel({
    required this.currencyId,
    required this.type,
    required this.amount,
    required this.category,
    this.notes,
    this.entryDate,
  });

  final String currencyId;
  final CashBoxEntryType type;

  /// The server refuses zero and anything below 0.01.
  final double amount;

  /// Required by the API — a movement nobody can account for later is worse
  /// than no record at all.
  final String category;

  final String? notes;

  /// `yyyy-MM-dd`. Null lets the server date it today.
  final String? entryDate;

  Map<String, dynamic> toJson() => {
    'currencyId': currencyId,
    'type': type.value,
    'amount': amount,
    'category': category,
    'notes': ?notes,
    'entryDate': ?entryDate,
  };
}

/// `SetCashBoxOpeningBalanceRequest`.
class SetCashBoxOpeningBalanceRequestModel {
  const SetCashBoxOpeningBalanceRequestModel({
    required this.currencyId,
    required this.amount,
    this.asOfDate,
  });

  final String currencyId;

  /// Zero is allowed here, unlike a movement: "the box started empty" is a
  /// real statement about the box.
  final double amount;

  /// `yyyy-MM-dd`.
  final String? asOfDate;

  Map<String, dynamic> toJson() => {
    'currencyId': currencyId,
    'amount': amount,
    'asOfDate': ?asOfDate,
  };
}
