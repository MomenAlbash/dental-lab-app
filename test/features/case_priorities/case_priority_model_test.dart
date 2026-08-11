import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/save_case_priority_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CasePriorityModel.fromJson', () {
    test('reads every field of the DTO', () {
      final priority = CasePriorityModel.fromJson(const {
        'id': 'p1',
        'name': 'Urgent',
        'nameAr': 'عاجلة',
        'description': 'خلال 24 ساعة',
        'displayOrder': 4,
        'isDefault': true,
        'isUnlimited': false,
        'freePerMonth': 3,
        'surcharge': 12.5,
        'badgeVariant': 'danger',
        'isActive': true,
        'isInUse': true,
      });

      expect(priority.id, 'p1');
      expect(priority.displayOrder, 4);
      expect(priority.isDefault, isTrue);
      expect(priority.freePerMonth, 3);
      expect(priority.surcharge, 12.5);
      expect(priority.badgeVariant, 'danger');
      expect(priority.isInUse, isTrue);
    });

    test('surcharge sent as an int still parses as a double', () {
      final priority = CasePriorityModel.fromJson(const {
        'id': 'p1',
        'surcharge': 10,
      });

      expect(priority.surcharge, 10.0);
    });

    test('missing optional fields fall back instead of throwing', () {
      final priority = CasePriorityModel.fromJson(const {'id': 'p1'});

      expect(priority.displayOrder, 0);
      expect(priority.isActive, isTrue);
      expect(priority.isDefault, isFalse);
    });
  });

  group('CasePriorityModel.displayName', () {
    test('prefers the Arabic name', () {
      const priority = CasePriorityModel(
        id: 'p1',
        name: 'Urgent',
        nameAr: 'عاجلة',
      );

      expect(priority.displayName, 'عاجلة');
    });

    test('falls back to the English name when Arabic is blank', () {
      const priority = CasePriorityModel(
        id: 'p1',
        name: 'Urgent',
        nameAr: '  ',
      );

      expect(priority.displayName, 'Urgent');
    });

    test('falls back to a dash when both names are missing', () {
      const priority = CasePriorityModel(id: 'p1');

      expect(priority.displayName, '—');
    });
  });

  test('SaveCasePriorityRequestModel serialises the API field names', () {
    const body = SaveCasePriorityRequestModel(
      name: 'Urgent',
      nameAr: 'عاجلة',
      displayOrder: 4,
      isDefault: true,
      freePerMonth: 3,
      surcharge: 12.5,
      badgeVariant: 'danger',
    );

    expect(body.toJson(), {
      'name': 'Urgent',
      'nameAr': 'عاجلة',
      'description': null,
      'displayOrder': 4,
      'isDefault': true,
      'isUnlimited': false,
      'freePerMonth': 3,
      'surcharge': 12.5,
      'badgeVariant': 'danger',
      'isActive': true,
    });
  });
}
