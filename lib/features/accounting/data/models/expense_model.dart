import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

/// `ExpenseDto`.
class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.laboratoryId,
    this.currency,
    this.amount = 0,
    this.category,
    this.notes,
    this.expenseDate,
    this.createdByName,
  });

  final String id;
  final String laboratoryId;
  final CurrencyModel? currency;
  final double amount;
  final String? category;
  final String? notes;
  final DateTime? expenseDate;
  final String? createdByName;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      laboratoryId: json['laboratoryId'] as String,
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String?,
      notes: json['notes'] as String?,
      expenseDate: json['expenseDate'] == null
          ? null
          : DateTime.tryParse(json['expenseDate'] as String),
      createdByName: json['createdByName'] as String?,
    );
  }
}

/// `CreateExpenseRequest`.
class CreateExpenseRequestModel {
  const CreateExpenseRequestModel({
    this.currencyId,
    required this.amount,
    required this.category,
    this.notes,
    required this.expenseDate,
  });

  final String? currencyId;
  final double amount;
  final String category;
  final String? notes;

  /// `yyyy-MM-dd`.
  final String expenseDate;

  Map<String, dynamic> toJson() => {
    'currencyId': currencyId,
    'amount': amount,
    'category': category,
    'notes': notes,
    'expenseDate': expenseDate,
  };
}
