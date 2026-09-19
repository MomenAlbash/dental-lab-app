/// Create/update payload for an inventory item
/// (`SaveInventoryItemRequest`, `POST/PUT /Inventory`). [name] and [unit]
/// are both required — the server has no fallback for either.
///
/// No quantity field: stock is never set directly here, only moved (see
/// `RecordInventoryMovementRequestModel`).
class SaveInventoryItemRequestModel {
  const SaveInventoryItemRequestModel({
    required this.name,
    required this.unit,
    this.lowStockThreshold,
    this.isActive = true,
  });

  final String name;
  final String unit;
  final double? lowStockThreshold;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'name': name,
    'unit': unit,
    'lowStockThreshold': lowStockThreshold,
    'isActive': isActive,
  };
}
