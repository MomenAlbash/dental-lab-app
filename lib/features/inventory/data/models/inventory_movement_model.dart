import 'package:dental_lab_app/features/inventory/data/models/inventory_movement_reason.dart';

/// One stock change (`InventoryMovementDto`,
/// `GET /Inventory/{id}/movements`) — a purchase landing, a technician
/// logging consumption, or a manual correction.
class InventoryMovementModel {
  const InventoryMovementModel({
    required this.id,
    required this.inventoryItemId,
    this.quantity = 0,
    this.reason = InventoryMovementReason.adjustmentIncrease,
    this.note,
    this.movementDate,
    this.createdByName,
    this.purchaseId,
  });

  final String id;
  final String inventoryItemId;

  /// Always positive on the wire — [reason] is what decides whether it added
  /// to stock or took from it.
  final double quantity;
  final InventoryMovementReason reason;
  final String? note;
  final DateTime? movementDate;
  final String? createdByName;

  /// Set only when [reason] is [InventoryMovementReason.purchase] — the
  /// purchase this movement came from.
  final String? purchaseId;

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) {
    return InventoryMovementModel(
      id: json['id'] as String,
      inventoryItemId: json['inventoryItemId'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      reason: InventoryMovementReason.fromApi(json['reason'] as int?),
      note: json['note'] as String?,
      movementDate: DateTime.tryParse(json['movementDate'] as String? ?? ''),
      createdByName: json['createdByName'] as String?,
      purchaseId: json['purchaseId'] as String?,
    );
  }
}
