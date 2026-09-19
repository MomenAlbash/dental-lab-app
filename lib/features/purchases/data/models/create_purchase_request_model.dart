/// Body of `POST /Purchases` (`CreatePurchaseRequest`). [supplierId],
/// [inventoryItemId] and [currencyId] are all required — the server has no
/// fallback for any of them. Recording one writes its own inventory movement
/// automatically (`InventoryMovementReason.purchase`); nothing else needs to
/// be sent to move stock.
class CreatePurchaseRequestModel {
  const CreatePurchaseRequestModel({
    required this.supplierId,
    required this.inventoryItemId,
    required this.currencyId,
    required this.quantity,
    required this.amount,
    this.notes,
    this.purchaseDate,
  });

  final String supplierId;
  final String inventoryItemId;
  final String currencyId;

  /// Always positive — how much of the item was bought.
  final double quantity;

  /// Always positive — what it cost, in [currencyId].
  final double amount;

  final String? notes;

  /// Defaults to today server-side when omitted.
  final String? purchaseDate;

  Map<String, dynamic> toJson() => {
    'supplierId': supplierId,
    'inventoryItemId': inventoryItemId,
    'currencyId': currencyId,
    'quantity': quantity,
    'amount': amount,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    if (purchaseDate != null) 'purchaseDate': purchaseDate,
  };
}
