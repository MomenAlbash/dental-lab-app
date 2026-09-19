import 'package:dental_lab_app/features/inventory/data/models/inventory_movement_reason.dart';

/// Body of `POST /Inventory/{id}/movements`
/// (`RecordInventoryMovementRequest`) — a manual stock movement: consumption
/// or a correction. A purchase records its own movement and never goes
/// through here, so [reason] must be one of
/// [InventoryMovementReason.manualReasons].
class RecordInventoryMovementRequestModel {
  const RecordInventoryMovementRequestModel({
    required this.quantity,
    required this.reason,
    this.note,
  }) : assert(
         reason != InventoryMovementReason.purchase,
         'A purchase records its own movement — it is never sent manually.',
       );

  /// Always positive — the sign is decided by [reason], not typed by hand.
  final double quantity;
  final InventoryMovementReason reason;
  final String? note;

  Map<String, dynamic> toJson() => {
    'quantity': quantity,
    'reason': reason.apiValue,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}
