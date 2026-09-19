import 'package:dental_lab_app/features/inventory/data/models/inventory_item_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_movement_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_movement_reason.dart';
import 'package:dental_lab_app/features/inventory/data/models/record_inventory_movement_request_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/save_inventory_item_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InventoryItemModel', () {
    test('parses a full item, including the low-stock flag', () {
      final item = InventoryItemModel.fromJson(const {
        'id': 'i1',
        'name': 'زيركون',
        'unit': 'غرام',
        'quantityOnHand': 12.5,
        'lowStockThreshold': 20,
        'isLowStock': true,
        'isActive': true,
        'canDelete': false,
        'deleteMessage': 'مستخدم بحالات',
      });

      expect(item.name, 'زيركون');
      expect(item.quantityOnHand, 12.5);
      expect(item.isLowStock, isTrue);
      expect(item.canDelete, isFalse);
      expect(item.deleteMessage, 'مستخدم بحالات');
    });

    test('a bare item defaults to zero stock and no threshold', () {
      final item = InventoryItemModel.fromJson(const {'id': 'i1'});

      expect(item.quantityOnHand, 0);
      expect(item.lowStockThreshold, isNull);
      expect(item.isLowStock, isFalse);
    });
  });

  group('SaveInventoryItemRequestModel', () {
    test('carries no quantity field — stock only ever moves', () {
      final json = const SaveInventoryItemRequestModel(
        name: 'زيركون',
        unit: 'غرام',
        lowStockThreshold: 5,
      ).toJson();

      expect(json['name'], 'زيركون');
      expect(json['unit'], 'غرام');
      expect(json['lowStockThreshold'], 5);
      expect(json.containsKey('quantityOnHand'), isFalse);
    });
  });

  group('InventoryMovementReason', () {
    test('sends the wire values the API declares', () {
      expect(InventoryMovementReason.purchase.apiValue, 0);
      expect(InventoryMovementReason.consumption.apiValue, 1);
      expect(InventoryMovementReason.adjustmentIncrease.apiValue, 2);
      expect(InventoryMovementReason.adjustmentDecrease.apiValue, 3);
    });

    test('purchase never appears among the manual reasons', () {
      // A purchase records its own movement automatically — offering it in a
      // manual-entry picker would let a person send a request the server
      // refuses.
      expect(
        InventoryMovementReason.manualReasons,
        isNot(contains(InventoryMovementReason.purchase)),
      );
    });

    test('only purchase and an upward adjustment read as an increase', () {
      expect(InventoryMovementReason.purchase.isIncrease, isTrue);
      expect(InventoryMovementReason.adjustmentIncrease.isIncrease, isTrue);
      expect(InventoryMovementReason.consumption.isIncrease, isFalse);
      expect(InventoryMovementReason.adjustmentDecrease.isIncrease, isFalse);
    });
  });

  group('InventoryMovementModel', () {
    test('parses a purchase-sourced movement', () {
      final movement = InventoryMovementModel.fromJson(const {
        'id': 'm1',
        'inventoryItemId': 'i1',
        'quantity': 500,
        'reason': 0,
        'movementDate': '2026-03-01T00:00:00Z',
        'purchaseId': 'p1',
      });

      expect(movement.reason, InventoryMovementReason.purchase);
      expect(movement.purchaseId, 'p1');
      expect(movement.quantity, 500);
    });
  });

  group('RecordInventoryMovementRequestModel', () {
    test('sends the reason as its wire value', () {
      final json = const RecordInventoryMovementRequestModel(
        quantity: 5,
        reason: InventoryMovementReason.consumption,
        note: 'استُهلك بحالة',
      ).toJson();

      expect(json['quantity'], 5);
      expect(json['reason'], 1);
      expect(json['note'], 'استُهلك بحالة');
    });

    test('refuses to construct a manual purchase movement', () {
      expect(
        () => RecordInventoryMovementRequestModel(
          quantity: 5,
          reason: InventoryMovementReason.purchase,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
