/// One stocked item (`InventoryItemDto`, `GET /Inventory`).
///
/// [quantityOnHand] is read-only here — there is no field for it on
/// [SaveInventoryItemRequestModel](save_inventory_item_request_model.dart):
/// stock only ever changes through a movement (a purchase, or a manual
/// consumption/adjustment), never by editing the item directly.
class InventoryItemModel {
  const InventoryItemModel({
    required this.id,
    this.laboratoryId,
    this.name,
    this.unit,
    this.quantityOnHand = 0,
    this.lowStockThreshold,
    this.isLowStock = false,
    this.isActive = true,
    this.canDelete = true,
    this.deleteMessage,
  });

  final String id;
  final String? laboratoryId;
  final String? name;
  final String? unit;
  final double quantityOnHand;

  /// Null means no threshold set — [isLowStock] never fires for this item.
  final double? lowStockThreshold;

  /// True once [quantityOnHand] has dropped to or below [lowStockThreshold].
  /// Server-computed, not re-derived here.
  final bool isLowStock;

  final bool isActive;
  final bool canDelete;
  final String? deleteMessage;

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as String,
      laboratoryId: json['laboratoryId'] as String?,
      name: json['name'] as String?,
      unit: json['unit'] as String?,
      quantityOnHand: (json['quantityOnHand'] as num?)?.toDouble() ?? 0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toDouble(),
      isLowStock: json['isLowStock'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      canDelete: json['canDelete'] as bool? ?? true,
      deleteMessage: json['deleteMessage'] as String?,
    );
  }
}
