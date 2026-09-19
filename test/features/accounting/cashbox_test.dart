import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/accounting/data/models/cashbox_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/accounting/logic/cashbox/cashbox_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/cashbox/cashbox_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountingRepo extends Mock implements AccountingRepo {}

void main() {
  group('CashBoxLedgerModel', () {
    test('reads a currency ledger with its own opening and closing', () {
      final ledger = CashBoxLedgerModel.fromJson({
        'currency': {'id': 'c1', 'code': 'USD', 'symbol': r'$'},
        'openingBalance': 100.0,
        'totalIn': 50.0,
        'totalOut': 20.0,
        'closingBalance': 130.0,
        'entries': [
          {
            'date': '2026-03-01T10:00:00Z',
            'description': 'دفعة من طبيب',
            'source': 1,
            'in': 50.0,
            'runningBalance': 150.0,
            'canDelete': false,
            'deleteMessage': 'الدفعات تُدار من شاشتها',
          },
          {
            'date': '2026-03-02T10:00:00Z',
            'description': 'سلفة',
            'source': 3,
            'entryId': 'e1',
            'out': 20.0,
            'runningBalance': 130.0,
            'canDelete': true,
          },
        ],
      });

      expect(ledger.currency?.code, 'USD');
      expect(ledger.closingBalance, 130.0);
      expect(ledger.entries.first.moneyIn, 50.0);
      expect(ledger.entries.last.moneyOut, 20.0);
    });

    test('only a manual line offers an id to delete', () {
      // A payment or expense line is read-only in the box and is managed from
      // its own screen — the server sends no entryId for those at all.
      final ledger = CashBoxLedgerModel.fromJson({
        'entries': [
          {'source': 1, 'in': 10.0},
          {'source': 3, 'entryId': 'e1', 'out': 5.0},
        ],
      });

      expect(ledger.entries.first.isManual, isFalse);
      expect(ledger.entries.first.entryId, isNull);
      expect(ledger.entries.last.isManual, isTrue);
      expect(ledger.entries.last.entryId, 'e1');
    });

    test('formats every amount with its own currency', () {
      // The whole point of one ledger per currency: a bare number is
      // ambiguous the moment a second box exists.
      final ledger = CashBoxLedgerModel.fromJson({
        'currency': {'id': 'c1', 'code': 'USD', 'symbol': r'$'},
        'closingBalance': 130.0,
      });

      expect(ledger.format(130), contains(r'$'));
    });
  });

  group('CreateCashBoxEntryRequestModel', () {
    test('sends the type as the API\'s own number', () {
      const request = CreateCashBoxEntryRequestModel(
        currencyId: 'c1',
        type: CashBoxEntryType.cashOut,
        amount: 25,
        category: 'سلفة',
      );

      expect(request.toJson()['type'], 2);
      expect(request.toJson()['category'], 'سلفة');
      // Absent rather than null: the server dates it today when not told.
      expect(request.toJson().containsKey('entryDate'), isFalse);
    });
  });

  group('CashboxCubit', () {
    late _MockAccountingRepo repo;
    late CashboxCubit cubit;

    setUp(() {
      repo = _MockAccountingRepo();
      when(
        () => repo.getCashboxLedger(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<CashBoxLedgerModel>>(const [
          CashBoxLedgerModel(closingBalance: 130),
        ]),
      );
      when(() => repo.getCashboxOpeningBalances()).thenAnswer(
        (_) async => Right<Failure, List<CashBoxOpeningBalanceModel>>(const [
          CashBoxOpeningBalanceModel(currencyId: 'c1', amount: 100),
        ]),
      );
      when(() => repo.getCurrencies()).thenAnswer(
        (_) async => Right<Failure, List<CurrencyModel>>(const [
          CurrencyModel(id: 'c1', code: 'USD'),
        ]),
      );

      cubit = CashboxCubit(repo);
    });

    tearDown(() => cubit.close());

    test('loads the ledger with its balances and currencies', () async {
      await cubit.load();

      final state = cubit.state as CashboxLoaded;
      expect(state.ledgers, hasLength(1));
      expect(state.openingBalances, hasLength(1));
      expect(state.currencies, hasLength(1));
    });

    test('a failed balances read still leaves the ledger readable', () async {
      // The balances are context for the ledger, not the thing itself.
      when(() => repo.getCashboxOpeningBalances()).thenAnswer(
        (_) async => Left<Failure, List<CashBoxOpeningBalanceModel>>(
          ServerFailure('فشل'),
        ),
      );

      await cubit.load();

      final state = cubit.state as CashboxLoaded;
      expect(state.ledgers, hasLength(1));
      expect(state.openingBalances, isEmpty);
    });

    test('a refused delete keeps the ledger and reports the server\'s reason', () async {
      await cubit.load();
      when(() => repo.deleteCashboxEntry(any())).thenAnswer(
        (_) async =>
            Left<Failure, void>(ServerFailure('مضى أكثر من 5 دقائق')),
      );

      final states = <CashboxState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.deleteEntry('e1');
      await sub.cancel();

      expect(
        states.whereType<CashboxActionError>().single.message,
        'مضى أكثر من 5 دقائق',
      );
      expect(cubit.state, isA<CashboxLoaded>());
    });

    test('a successful write reloads rather than patching locally', () async {
      // Every entry changes a running balance that each line below it
      // carries; recomputing on the client would re-derive what the ledger
      // endpoint exists to answer.
      await cubit.load();
      when(() => repo.deleteCashboxEntry(any())).thenAnswer(
        (_) async => const Right<Failure, void>(null),
      );

      await cubit.deleteEntry('e1');

      verify(
        () => repo.getCashboxLedger(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(2);
    });
  });
}
