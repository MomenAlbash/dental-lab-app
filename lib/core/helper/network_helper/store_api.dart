import 'dart:developer';

import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_item_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_movement_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/record_inventory_movement_request_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/save_inventory_item_request_model.dart';
import 'package:dental_lab_app/features/purchases/data/models/create_purchase_request_model.dart';
import 'package:dental_lab_app/features/purchases/data/models/purchase_model.dart';
import 'package:dental_lab_app/features/store_reports/data/models/monthly_feasibility_model.dart';
import 'package:dental_lab_app/features/suppliers/data/models/save_supplier_request_model.dart';
import 'package:dental_lab_app/features/suppliers/data/models/supplier_model.dart';

/// The `store` endpoints — split out of
/// [ApiService], reached through the same instance.
extension StoreApi on ApiService {
  // ---------------------------------------------------------------------
  // Inventory (`/Inventory`)
  // ---------------------------------------------------------------------

  Future<List<InventoryItemModel>> getInventoryItems({
    bool includeInactive = false,
    String? token,
  }) async {
    log('Fetching inventory items (includeInactive: $includeInactive)');

    final responseData = await Api().get(
      url: 'Inventory?includeInactive=$includeInactive',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => InventoryItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InventoryItemModel> createInventoryItem({
    required SaveInventoryItemRequestModel body,
    String? token,
  }) async {
    log('Creating inventory item: ${body.toJson()}');

    final response = await Api().post(
      url: 'Inventory',
      body: body.toJson(),
      token: token,
    );

    return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<InventoryItemModel> updateInventoryItem({
    required String id,
    required SaveInventoryItemRequestModel body,
    String? token,
  }) async {
    log('Updating inventory item $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'Inventory/$id',
      body: body.toJson(),
      token: token,
    );

    return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteInventoryItem({required String id, String? token}) async {
    log('Deleting inventory item: $id');

    await Api().delete(url: 'Inventory/$id', token: token);
  }

  /// `GET /Inventory/{id}/movements` — this item's full stock history.
  Future<List<InventoryMovementModel>> getInventoryMovements({
    required String id,
    String? token,
  }) async {
    log('Fetching inventory movements for item: $id');

    final responseData = await Api().get(
      url: 'Inventory/$id/movements',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => InventoryMovementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /Inventory/{id}/movements` — a manual movement (consumption or a
  /// correction); a purchase records its own and never calls this.
  Future<InventoryMovementModel> recordInventoryMovement({
    required String id,
    required RecordInventoryMovementRequestModel body,
    String? token,
  }) async {
    log('Recording inventory movement for item $id: ${body.toJson()}');

    final response = await Api().post(
      url: 'Inventory/$id/movements',
      body: body.toJson(),
      token: token,
    );

    return InventoryMovementModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ---------------------------------------------------------------------
  // Suppliers (`/Suppliers`)
  // ---------------------------------------------------------------------

  Future<List<SupplierModel>> getSuppliers({
    bool includeInactive = false,
    String? token,
  }) async {
    log('Fetching suppliers (includeInactive: $includeInactive)');

    final responseData = await Api().get(
      url: 'Suppliers?includeInactive=$includeInactive',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => SupplierModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SupplierModel> createSupplier({
    required SaveSupplierRequestModel body,
    String? token,
  }) async {
    log('Creating supplier: ${body.toJson()}');

    final response = await Api().post(
      url: 'Suppliers',
      body: body.toJson(),
      token: token,
    );

    return SupplierModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SupplierModel> updateSupplier({
    required String id,
    required SaveSupplierRequestModel body,
    String? token,
  }) async {
    log('Updating supplier $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'Suppliers/$id',
      body: body.toJson(),
      token: token,
    );

    return SupplierModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSupplier({required String id, String? token}) async {
    log('Deleting supplier: $id');

    await Api().delete(url: 'Suppliers/$id', token: token);
  }

  // ---------------------------------------------------------------------
  // Purchases (`/Purchases`) — no `/{id}` route: a purchase is recorded and
  // read back, never edited or deleted.
  // ---------------------------------------------------------------------

  Future<List<PurchaseModel>> getPurchases({
    String? from,
    String? to,
    String? token,
  }) async {
    log('Fetching purchases (from: $from, to: $to)');

    final params = <String>[
      if (from != null && from.isNotEmpty) 'from=$from',
      if (to != null && to.isNotEmpty) 'to=$to',
    ];

    final responseData = await Api().get(
      url: params.isEmpty ? 'Purchases' : 'Purchases?${params.join('&')}',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => PurchaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PurchaseModel> createPurchase({
    required CreatePurchaseRequestModel body,
    String? token,
  }) async {
    log('Recording purchase: ${body.toJson()}');

    final response = await Api().post(
      url: 'Purchases',
      body: body.toJson(),
      token: token,
    );

    return PurchaseModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Store reports (`/store/feasibility`)
  // ---------------------------------------------------------------------

  /// `GET /store/feasibility` — الجدوى الاقتصادية الشهرية, one series per
  /// currency. [months] is how many months back to include; null leaves it
  /// to the server's own default.
  Future<MonthlyFeasibilityModel> getStoreFeasibility({
    int? months,
    List<String>? laboratoryIds,
    String? token,
  }) async {
    log('Fetching store feasibility (months: $months)');

    final params = <String>[
      if (months != null) 'months=$months',
      for (final id in laboratoryIds ?? const <String>[])
        'laboratoryIds=${Uri.encodeQueryComponent(id)}',
    ];

    final responseData = await Api().get(
      url: params.isEmpty
          ? 'store/feasibility'
          : 'store/feasibility?${params.join('&')}',
      token: token,
    );

    return MonthlyFeasibilityModel.fromJson(
      responseData as Map<String, dynamic>,
    );
  }


}
