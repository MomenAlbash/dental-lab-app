import 'package:dental_lab_app/features/purchases/data/models/create_purchase_request_model.dart';
import 'package:dental_lab_app/features/purchases/data/models/purchase_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurchaseModel', () {
    test('parses a full purchase, currency included', () {
      final purchase = PurchaseModel.fromJson(const {
        'id': 'p1',
        'supplierId': 's1',
        'supplierName': 'دنتكو',
        'inventoryItemId': 'i1',
        'inventoryItemName': 'زيركون',
        'inventoryItemUnit': 'غرام',
        'currency': {'id': 'c1', 'name': 'ليرة سورية', 'code': 'SYP'},
        'quantity': 500,
        'amount': 250000,
        'purchaseDate': '2026-03-01T00:00:00Z',
        'createdByName': 'أحمد',
      });

      expect(purchase.supplierName, 'دنتكو');
      expect(purchase.inventoryItemName, 'زيركون');
      expect(purchase.currency?.code, 'SYP');
      expect(purchase.quantity, 500);
      expect(purchase.amount, 250000);
    });

    test('a bare purchase parses with zeroed totals', () {
      final purchase = PurchaseModel.fromJson(const {'id': 'p1'});

      expect(purchase.quantity, 0);
      expect(purchase.amount, 0);
      expect(purchase.currency, isNull);
    });
  });

  group('CreatePurchaseRequestModel', () {
    test('omits notes and date when not given', () {
      final json = const CreatePurchaseRequestModel(
        supplierId: 's1',
        inventoryItemId: 'i1',
        currencyId: 'c1',
        quantity: 500,
        amount: 250000,
      ).toJson();

      expect(json['supplierId'], 's1');
      expect(json['quantity'], 500);
      expect(json.containsKey('notes'), isFalse);
      expect(json.containsKey('purchaseDate'), isFalse);
    });

    test('sends notes and the purchase date when given', () {
      final json = const CreatePurchaseRequestModel(
        supplierId: 's1',
        inventoryItemId: 'i1',
        currencyId: 'c1',
        quantity: 500,
        amount: 250000,
        notes: 'دفعة أولى',
        purchaseDate: '2026-03-01',
      ).toJson();

      expect(json['notes'], 'دفعة أولى');
      expect(json['purchaseDate'], '2026-03-01');
    });
  });
}
