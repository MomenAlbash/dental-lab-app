import 'package:dental_lab_app/features/suppliers/data/models/save_supplier_request_model.dart';
import 'package:dental_lab_app/features/suppliers/data/models/supplier_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupplierModel', () {
    test('parses a full supplier', () {
      final supplier = SupplierModel.fromJson(const {
        'id': 's1',
        'name': 'دنتكو',
        'phone': '011-1234567',
        'notes': 'مورد الزيركون الرئيسي',
        'isActive': true,
        'canDelete': false,
        'deleteMessage': 'له مشتريات مسجّلة',
      });

      expect(supplier.name, 'دنتكو');
      expect(supplier.phone, '011-1234567');
      expect(supplier.canDelete, isFalse);
      expect(supplier.deleteMessage, 'له مشتريات مسجّلة');
    });

    test('a bare supplier defaults to active with nothing else set', () {
      final supplier = SupplierModel.fromJson(const {'id': 's1'});

      expect(supplier.isActive, isTrue);
      expect(supplier.phone, isNull);
      expect(supplier.notes, isNull);
    });
  });

  group('SaveSupplierRequestModel', () {
    test('sends every key, phone and notes included when empty', () {
      final json = const SaveSupplierRequestModel(name: 'دنتكو').toJson();

      expect(json['name'], 'دنتكو');
      expect(json.containsKey('phone'), isTrue);
      expect(json['phone'], isNull);
      expect(json['isActive'], isTrue);
    });
  });
}
