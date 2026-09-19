import 'package:dental_lab_app/features/currencies/data/models/currency_assignment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyAssignmentModel', () {
    test('defaultCurrency resolves the named id out of the set', () {
      final assignment = CurrencyAssignmentModel.fromJson(const {
        'currencies': [
          {'id': 'c1', 'code': 'USD'},
          {'id': 'c2', 'code': 'SYP'},
        ],
        'defaultCurrencyId': 'c2',
      });

      expect(assignment.defaultCurrency?.code, 'SYP');
    });

    test('a default naming a currency no longer in the set reads as none', () {
      final assignment = CurrencyAssignmentModel.fromJson(const {
        'currencies': [
          {'id': 'c1', 'code': 'USD'},
        ],
        'defaultCurrencyId': 'c2',
      });

      expect(assignment.defaultCurrency, isNull);
    });

    test('no default at all is none rather than the first row', () {
      final assignment = CurrencyAssignmentModel.fromJson(const {
        'currencies': [
          {'id': 'c1', 'code': 'USD'},
        ],
      });

      expect(assignment.defaultCurrency, isNull);
    });

    test('isInherited is carried through — it is what the screen branches on', () {
      final inherited = CurrencyAssignmentModel.fromJson(const {
        'currencies': [],
        'isInherited': true,
      });
      final own = CurrencyAssignmentModel.fromJson(const {'currencies': []});

      expect(inherited.isInherited, isTrue);
      expect(own.isInherited, isFalse);
    });
  });

  group('SetLaboratoryCurrenciesRequestModel', () {
    test('sends the set and the default together', () {
      final json = const SetLaboratoryCurrenciesRequestModel(
        currencyIds: ['c1', 'c2'],
        defaultCurrencyId: 'c1',
      ).toJson();

      expect(json['currencyIds'], ['c1', 'c2']);
      expect(json['defaultCurrencyId'], 'c1');
    });

    test('a null default is sent, not omitted — it clears the choice', () {
      final json = const SetLaboratoryCurrenciesRequestModel(
        currencyIds: ['c1'],
      ).toJson();

      expect(json.containsKey('defaultCurrencyId'), isTrue);
      expect(json['defaultCurrencyId'], isNull);
    });
  });

  group('SetClinicCurrenciesRequestModel', () {
    test('an empty list is sent, since it clears the override', () {
      final json = const SetClinicCurrenciesRequestModel(
        currencyIds: [],
      ).toJson();

      expect(json['currencyIds'], isEmpty);
    });

    test('carries no default — that stays the laboratory\'s call', () {
      final json = const SetClinicCurrenciesRequestModel(
        currencyIds: ['c1'],
      ).toJson();

      expect(json.containsKey('defaultCurrencyId'), isFalse);
    });
  });
}
