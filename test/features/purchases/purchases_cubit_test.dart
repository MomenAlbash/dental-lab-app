import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/purchases/data/models/purchase_model.dart';
import 'package:dental_lab_app/features/purchases/data/repos/purchases_repo.dart';
import 'package:dental_lab_app/features/purchases/logic/purchases/purchases_cubit.dart';
import 'package:dental_lab_app/features/purchases/logic/purchases/purchases_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPurchasesRepo extends Mock implements PurchasesRepo {}

PurchaseModel _purchase(String id, String isoDate) =>
    PurchaseModel(id: id, purchaseDate: DateTime.parse(isoDate));

void main() {
  late _MockPurchasesRepo repo;
  late PurchasesCubit cubit;

  setUp(() {
    repo = _MockPurchasesRepo();
    cubit = PurchasesCubit(repo);
  });

  tearDown(() => cubit.close());

  test('loads the purchase history, newest first', () async {
    // The API returns rows in no particular order; the oldest-first fixture
    // here would read as "the list wasn't sorted at all" if the cubit didn't
    // actually do it.
    when(
      () => repo.getPurchases(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => right([
        _purchase('old', '2026-01-01T00:00:00Z'),
        _purchase('new', '2026-03-01T00:00:00Z'),
      ]),
    );

    await cubit.getPurchases();

    final loaded = cubit.state as PurchasesLoaded;
    expect(loaded.purchases.map((p) => p.id), ['new', 'old']);
  });

  test('a fetch failure reports the reason', () async {
    when(
      () => repo.getPurchases(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

    await cubit.getPurchases();

    expect(cubit.state, isA<PurchasesError>());
    expect((cubit.state as PurchasesError).message, 'لا يوجد اتصال');
  });
}
