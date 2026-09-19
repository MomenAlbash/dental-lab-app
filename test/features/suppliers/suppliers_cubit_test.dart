import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/suppliers/data/models/save_supplier_request_model.dart';
import 'package:dental_lab_app/features/suppliers/data/models/supplier_model.dart';
import 'package:dental_lab_app/features/suppliers/data/repos/suppliers_repo.dart';
import 'package:dental_lab_app/features/suppliers/logic/suppliers/suppliers_cubit.dart';
import 'package:dental_lab_app/features/suppliers/logic/suppliers/suppliers_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSuppliersRepo extends Mock implements SuppliersRepo {}

const _dentco = SupplierModel(id: 's1', name: 'دنتكو');
const _zircomax = SupplierModel(id: 's2', name: 'زيركوماكس');

void main() {
  setUpAll(() {
    registerFallbackValue(const SaveSupplierRequestModel(name: 'x'));
  });

  late _MockSuppliersRepo repo;
  late SuppliersCubit cubit;

  setUp(() {
    repo = _MockSuppliersRepo();
    cubit = SuppliersCubit(repo);
  });

  tearDown(() => cubit.close());

  test('loads the supplier list', () async {
    when(
      () => repo.getSuppliers(includeInactive: any(named: 'includeInactive')),
    ).thenAnswer((_) async => right(const [_dentco, _zircomax]));

    await cubit.getSuppliers();

    final loaded = cubit.state as SuppliersLoaded;
    expect(loaded.suppliers, [_dentco, _zircomax]);
  });

  test('a fetch failure reports the reason', () async {
    when(
      () => repo.getSuppliers(includeInactive: any(named: 'includeInactive')),
    ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

    await cubit.getSuppliers();

    expect(cubit.state, isA<SuppliersError>());
    expect((cubit.state as SuppliersError).message, 'لا يوجد اتصال');
  });

  test('adding a supplier appends it to the loaded list', () async {
    when(
      () => repo.getSuppliers(includeInactive: any(named: 'includeInactive')),
    ).thenAnswer((_) async => right(const [_dentco]));
    when(
      () => repo.createSupplier(any()),
    ).thenAnswer((_) async => right(_zircomax));

    await cubit.getSuppliers();
    await cubit.addSupplier(const SaveSupplierRequestModel(name: 'زيركوماكس'));

    final loaded = cubit.state as SuppliersLoaded;
    expect(loaded.suppliers, [_dentco, _zircomax]);
  });

  test('a failed add reports and keeps the existing list', () async {
    when(
      () => repo.getSuppliers(includeInactive: any(named: 'includeInactive')),
    ).thenAnswer((_) async => right(const [_dentco]));
    when(
      () => repo.createSupplier(any()),
    ).thenAnswer((_) async => left(ServerFailure('مرفوض')));

    await cubit.getSuppliers();

    final states = <SuppliersState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.addSupplier(const SaveSupplierRequestModel(name: 'زيركوماكس'));
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(states.whereType<SuppliersActionError>().single.message, 'مرفوض');
    final last = states.last as SuppliersLoaded;
    expect(last.suppliers, [_dentco]);
  });

  test('editing a supplier replaces it in place', () async {
    when(
      () => repo.getSuppliers(includeInactive: any(named: 'includeInactive')),
    ).thenAnswer((_) async => right(const [_dentco, _zircomax]));
    const updated = SupplierModel(id: 's1', name: 'دنتكو سوريا');
    when(
      () => repo.updateSupplier(
        id: any(named: 'id'),
        requestBody: any(named: 'requestBody'),
      ),
    ).thenAnswer((_) async => right(updated));

    await cubit.getSuppliers();
    await cubit.editSupplier(
      id: 's1',
      requestBody: const SaveSupplierRequestModel(name: 'دنتكو سوريا'),
    );

    final loaded = cubit.state as SuppliersLoaded;
    expect(loaded.suppliers, [updated, _zircomax]);
  });

  test('removing a supplier drops it from the list', () async {
    when(
      () => repo.getSuppliers(includeInactive: any(named: 'includeInactive')),
    ).thenAnswer((_) async => right(const [_dentco, _zircomax]));
    when(() => repo.deleteSupplier(any())).thenAnswer((_) async => right(null));

    await cubit.getSuppliers();
    await cubit.removeSupplier('s1');

    final loaded = cubit.state as SuppliersLoaded;
    expect(loaded.suppliers, [_zircomax]);
  });
}
