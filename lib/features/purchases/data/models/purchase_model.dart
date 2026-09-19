import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

/// One inventory purchase (`PurchaseDto`, `GET /Purchases`) — a supplier, an
/// inventory item, and what it cost. Recording one also writes its own
/// inventory movement server-side; there is nothing more to do here to move
/// stock.
class PurchaseModel {
  const PurchaseModel({
    required this.id,
    this.laboratoryId,
    this.supplierId,
    this.supplierName,
    this.inventoryItemId,
    this.inventoryItemName,
    this.inventoryItemUnit,
    this.currency,
    this.quantity = 0,
    this.amount = 0,
    this.notes,
    this.purchaseDate,
    this.createdByName,
  });

  final String id;
  final String? laboratoryId;
  final String? supplierId;
  final String? supplierName;
  final String? inventoryItemId;
  final String? inventoryItemName;
  final String? inventoryItemUnit;
  final CurrencyModel? currency;
  final double quantity;
  final double amount;
  final String? notes;
  final DateTime? purchaseDate;
  final String? createdByName;

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as String,
      laboratoryId: json['laboratoryId'] as String?,
      supplierId: json['supplierId'] as String?,
      supplierName: json['supplierName'] as String?,
      inventoryItemId: json['inventoryItemId'] as String?,
      inventoryItemName: json['inventoryItemName'] as String?,
      inventoryItemUnit: json['inventoryItemUnit'] as String?,
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      purchaseDate: DateTime.tryParse(json['purchaseDate'] as String? ?? ''),
      createdByName: json['createdByName'] as String?,
    );
  }
}
