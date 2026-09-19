import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_item_model.dart';
import 'package:dental_lab_app/features/inventory/data/repos/inventory_repo.dart';
import 'package:dental_lab_app/features/purchases/data/models/create_purchase_request_model.dart';
import 'package:dental_lab_app/features/purchases/data/models/purchase_model.dart';
import 'package:dental_lab_app/features/purchases/data/repos/purchases_repo.dart';
import 'package:dental_lab_app/features/purchases/logic/purchase_form/purchase_form_cubit.dart';
import 'package:dental_lab_app/features/purchases/logic/purchase_form/purchase_form_state.dart';
import 'package:dental_lab_app/features/suppliers/data/models/supplier_model.dart';
import 'package:dental_lab_app/features/suppliers/data/repos/suppliers_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPurchasesRepo extends Mock implements PurchasesRepo {}

class _MockSuppliersRepo extends Mock implements SuppliersRepo {}

class _MockInventoryRepo extends Mock implements InventoryRepo {}

class _MockAccountingRepo extends Mock implements AccountingRepo {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const CreatePurchaseRequestModel(
        supplierId: 's1',
        inventoryItemId: 'i1',
        currencyId: 'c1',
        quantity: 1,
        amount: 1,
      ),
    );
  });

  late _MockPurchasesRepo purchasesRepo;
  late _MockSuppliersRepo suppliersRepo;
  late _MockInventoryRepo inventoryRepo;
  late _MockAccountingRepo accountingRepo;
  late PurchaseFormCubit cubit;

  setUp(() {
    purchasesRepo = _MockPurchasesRepo();
    suppliersRepo = _MockSuppliersRepo();
    inventoryRepo = _MockInventoryRepo();
    accountingRepo = _MockAccountingRepo();
    cubit = PurchaseFormCubit(
      purchasesRepo,
      suppliersRepo,
      inventoryRepo,
      accountingRepo,
    );
  });

  tearDown(() => cubit.close());

  test('loads suppliers, inventory items and currencies together', () async {
    when(
      () => suppliersRepo.getSuppliers(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer(
      (_) async => right(const [SupplierModel(id: 's1', name: 'دنتكو')]),
    );
    when(
      () => inventoryRepo.getInventoryItems(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer(
      (_) async => right(const [
        InventoryItemModel(id: 'i1', name: 'زيركون', unit: 'غرام'),
      ]),
    );
    when(() => accountingRepo.getCurrencies()).thenAnswer(
      (_) async => right(const [CurrencyModel(id: 'c1', name: 'ليرة سورية')]),
    );

    await cubit.loadCatalog();

    final loaded = cubit.state as PurchaseFormCatalogLoaded;
    expect(loaded.suppliers.single.name, 'دنتكو');
    expect(loaded.inventoryItems.single.name, 'زيركون');
    expect(loaded.currencies.single.name, 'ليرة سورية');
  });

  test('a failed catalog fetch reports the reason', () async {
    // Every source is asked regardless — the same "load everything, fold
    // whichever failed" shape `InvoiceFormCubit.loadCatalog` uses.
    when(
      () => suppliersRepo.getSuppliers(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));
    when(
      () => inventoryRepo.getInventoryItems(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer((_) async => right(const []));
    when(
      () => accountingRepo.getCurrencies(),
    ).thenAnswer((_) async => right(const []));

    await cubit.loadCatalog();

    expect(cubit.state, isA<PurchaseFormCatalogError>());
    expect((cubit.state as PurchaseFormCatalogError).message, 'لا يوجد اتصال');
  });

  test('submitting records the purchase', () async {
    const body = CreatePurchaseRequestModel(
      supplierId: 's1',
      inventoryItemId: 'i1',
      currencyId: 'c1',
      quantity: 500,
      amount: 250000,
    );
    when(
      () => purchasesRepo.createPurchase(any()),
    ).thenAnswer((_) async => right(const PurchaseModel(id: 'p1')));

    await cubit.submit(body);

    expect((cubit.state as PurchaseFormSuccess).purchase.id, 'p1');
    verify(() => purchasesRepo.createPurchase(body)).called(1);
  });

  test('a failed submit reports the reason', () async {
    when(
      () => purchasesRepo.createPurchase(any()),
    ).thenAnswer((_) async => left(ServerFailure('مرفوض')));

    await cubit.submit(
      const CreatePurchaseRequestModel(
        supplierId: 's1',
        inventoryItemId: 'i1',
        currencyId: 'c1',
        quantity: 1,
        amount: 1,
      ),
    );

    expect((cubit.state as PurchaseFormError).message, 'مرفوض');
  });
}
