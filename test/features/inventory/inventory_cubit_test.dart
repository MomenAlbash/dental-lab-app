import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_item_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/save_inventory_item_request_model.dart';
import 'package:dental_lab_app/features/inventory/data/repos/inventory_repo.dart';
import 'package:dental_lab_app/features/inventory/logic/inventory/inventory_cubit.dart';
import 'package:dental_lab_app/features/inventory/logic/inventory/inventory_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockInventoryRepo extends Mock implements InventoryRepo {}

const _zircon = InventoryItemModel(id: 'i1', name: 'زيركون', unit: 'غرام');
const _resin = InventoryItemModel(id: 'i2', name: 'راتنج', unit: 'مل');

void main() {
  setUpAll(() {
    registerFallbackValue(
      const SaveInventoryItemRequestModel(name: 'x', unit: 'y'),
    );
  });

  late _MockInventoryRepo repo;
  late InventoryCubit cubit;

  setUp(() {
    repo = _MockInventoryRepo();
    cubit = InventoryCubit(repo);
  });

  tearDown(() => cubit.close());

  test('loads the catalog', () async {
    when(
      () => repo.getInventoryItems(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer((_) async => right(const [_zircon, _resin]));

    await cubit.getInventoryItems();

    final loaded = cubit.state as InventoryLoaded;
    expect(loaded.items, [_zircon, _resin]);
  });

  test('a fetch failure reports the reason', () async {
    when(
      () => repo.getInventoryItems(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

    await cubit.getInventoryItems();

    expect(cubit.state, isA<InventoryError>());
    expect((cubit.state as InventoryError).message, 'لا يوجد اتصال');
  });

  test('adding an item appends it to the loaded list', () async {
    when(
      () => repo.getInventoryItems(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer((_) async => right(const [_zircon]));
    when(
      () => repo.createInventoryItem(any()),
    ).thenAnswer((_) async => right(_resin));

    await cubit.getInventoryItems();
    await cubit.addItem(
      const SaveInventoryItemRequestModel(name: 'راتنج', unit: 'مل'),
    );

    final loaded = cubit.state as InventoryLoaded;
    expect(loaded.items, [_zircon, _resin]);
  });

  test('a failed add reports and keeps the existing list', () async {
    when(
      () => repo.getInventoryItems(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer((_) async => right(const [_zircon]));
    when(
      () => repo.createInventoryItem(any()),
    ).thenAnswer((_) async => left(ServerFailure('مرفوض')));

    await cubit.getInventoryItems();

    final states = <InventoryState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.addItem(
      const SaveInventoryItemRequestModel(name: 'راتنج', unit: 'مل'),
    );
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(states.whereType<InventoryActionError>().single.message, 'مرفوض');
    final last = states.last as InventoryLoaded;
    expect(last.items, [_zircon]);
  });

  test('editing an item replaces it in place', () async {
    when(
      () => repo.getInventoryItems(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer((_) async => right(const [_zircon, _resin]));
    const updated = InventoryItemModel(
      id: 'i1',
      name: 'زيركون ملوّن',
      unit: 'غرام',
    );
    when(
      () => repo.updateInventoryItem(
        id: any(named: 'id'),
        requestBody: any(named: 'requestBody'),
      ),
    ).thenAnswer((_) async => right(updated));

    await cubit.getInventoryItems();
    await cubit.editItem(
      id: 'i1',
      requestBody: const SaveInventoryItemRequestModel(
        name: 'زيركون ملوّن',
        unit: 'غرام',
      ),
    );

    final loaded = cubit.state as InventoryLoaded;
    expect(loaded.items, [updated, _resin]);
  });

  test('removing an item drops it from the list', () async {
    when(
      () => repo.getInventoryItems(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer((_) async => right(const [_zircon, _resin]));
    when(
      () => repo.deleteInventoryItem(any()),
    ).thenAnswer((_) async => right(null));

    await cubit.getInventoryItems();
    await cubit.removeItem('i1');

    final loaded = cubit.state as InventoryLoaded;
    expect(loaded.items, [_resin]);
  });
}
