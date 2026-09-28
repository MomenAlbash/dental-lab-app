import 'dart:developer';

import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/accounting/data/models/accounting_statistics_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/cashbox_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/create_invoice_request_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/doctor_statement_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/expense_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/invoice_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';
import 'package:dental_lab_app/features/currencies/data/models/save_currency_request_models.dart';
import 'package:dio/dio.dart';

/// The `accounting` endpoints — split out of
/// [ApiService], reached through the same instance.
extension AccountingApi on ApiService {
  // ------------------------------------------------------------ accounting ---

  /// `GET /Accounting/invoices`. Every filter is optional; the query is
  /// built with only the ones given rather than sending `null` params.
  Future<List<InvoiceModel>> getInvoices({
    String? doctorId,
    String? from,
    String? to,
    InvoiceStatus? status,
    String? search,
    String? token,
  }) async {
    log('Fetching invoices');

    final params = <String>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add('$key=${Uri.encodeQueryComponent(value)}');
      }
    }

    add('doctorId', doctorId);
    add('from', from);
    add('to', to);
    add('search', search);
    if (status != null) params.add('status=${status.value}');

    final url = params.isEmpty
        ? 'Accounting/invoices'
        : 'Accounting/invoices?${params.join('&')}';
    final responseData = await Api().get(url: url, token: token);

    return (responseData as List<dynamic>)
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InvoiceModel> getInvoiceById({
    required String id,
    String? token,
  }) async {
    log('Fetching invoice by id: $id');

    final responseData = await Api().get(
      url: 'Accounting/invoices/$id',
      token: token,
    );

    return InvoiceModel.fromJson(responseData as Map<String, dynamic>);
  }

  /// `GET /Accounting/statistics`.
  Future<AccountingStatisticsModel> getAccountingStatistics({
    String? doctorId,
    String? from,
    String? to,
    String? token,
  }) async {
    log('Fetching accounting statistics');

    final params = <String>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add('$key=${Uri.encodeQueryComponent(value)}');
      }
    }

    add('doctorId', doctorId);
    add('from', from);
    add('to', to);

    final url = params.isEmpty
        ? 'Accounting/statistics'
        : 'Accounting/statistics?${params.join('&')}';
    final responseData = await Api().get(url: url, token: token);

    return AccountingStatisticsModel.fromJson(
      responseData as Map<String, dynamic>,
    );
  }

  /// `GET /Accounting/payments` — the lab's payment history.
  Future<List<PaymentModel>> getPayments({
    String? doctorId,
    String? from,
    String? to,
    String? token,
  }) async {
    log('Fetching payments');

    final params = <String>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add('$key=${Uri.encodeQueryComponent(value)}');
      }
    }

    add('doctorId', doctorId);
    add('from', from);
    add('to', to);

    final url = params.isEmpty
        ? 'Accounting/payments'
        : 'Accounting/payments?${params.join('&')}';
    final responseData = await Api().get(url: url, token: token);

    return (responseData as List<dynamic>)
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /Accounting/payments/pending`.
  Future<List<PaymentModel>> getPendingPayments({String? token}) async {
    log('Fetching pending payments');

    final responseData = await Api().get(
      url: 'Accounting/payments/pending',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /Accounting/payments/{id}/verify?approve=`.
  Future<PaymentModel> verifyPayment({
    required String id,
    required bool approve,
    String? notes,
    String? token,
  }) async {
    log('Verifying payment $id (approve: $approve)');

    final response = await Api().post(
      url: 'Accounting/payments/$id/verify?approve=$approve',
      body: {'notes': notes},
      token: token,
    );

    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /Accounting/payments/manual` — multipart; [receiptFilePath] is
  /// optional (a doctor may pay in person with nothing to attach).
  Future<PaymentModel> createManualPayment({
    required String invoiceId,
    required String doctorId,
    required double amount,
    PaymentMethod? method,
    String? notes,
    String? receiptFilePath,
    String? token,
  }) async {
    log('Recording manual payment for invoice $invoiceId');

    final formData = FormData.fromMap({
      'InvoiceId': invoiceId,
      'DoctorId': doctorId,
      'Amount': amount,
      if (method != null) 'Method': method.value,
      'Notes': ?notes,
      if (receiptFilePath != null)
        'receipt': await MultipartFile.fromFile(receiptFilePath),
    });

    final response = await Api().post(
      url: 'Accounting/payments/manual',
      body: formData,
      isFormData: true,
      token: token,
    );

    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /Accounting/expenses`.
  Future<List<ExpenseModel>> getExpenses({
    String? from,
    String? to,
    String? token,
  }) async {
    log('Fetching expenses');

    final params = <String>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add('$key=${Uri.encodeQueryComponent(value)}');
      }
    }

    add('from', from);
    add('to', to);

    final url = params.isEmpty
        ? 'Accounting/expenses'
        : 'Accounting/expenses?${params.join('&')}';
    final responseData = await Api().get(url: url, token: token);

    return (responseData as List<dynamic>)
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExpenseModel> createExpense({
    required CreateExpenseRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create Expense request with: ${logSafe(body)}');

    final response = await Api().post(
      url: 'Accounting/expenses',
      body: body,
      token: token,
    );

    return ExpenseModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---- Cash box ---------------------------------------------------------
  //
  // The laboratory's actual drawer: an opening balance per currency, plus
  // every verified payment, expense and manual movement since. One ledger per
  // currency, never blended — see [CashBoxLedgerModel].

  /// `GET /Accounting/cashbox/ledger` — one ledger per currency.
  Future<List<CashBoxLedgerModel>> getCashboxLedger({
    String? from,
    String? to,
    String? token,
  }) async {
    log('Fetching cashbox ledger');

    final params = <String>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add('$key=${Uri.encodeQueryComponent(value)}');
      }
    }

    add('from', from);
    add('to', to);

    final responseData = await Api().get(
      url: params.isEmpty
          ? 'Accounting/cashbox/ledger'
          : 'Accounting/cashbox/ledger?${params.join('&')}',
      token: token,
    );

    return decodeJsonList(responseData, CashBoxLedgerModel.fromJson);
  }

  /// `GET /Accounting/cashbox/opening-balances`.
  Future<List<CashBoxOpeningBalanceModel>> getCashboxOpeningBalances({
    String? token,
  }) async {
    log('Fetching cashbox opening balances');

    final responseData = await Api().get(
      url: 'Accounting/cashbox/opening-balances',
      token: token,
    );

    return decodeJsonList(responseData, CashBoxOpeningBalanceModel.fromJson);
  }

  /// `POST /Accounting/cashbox/opening-balance` — sets (or replaces) what the
  /// box held in one currency before the ledger begins.
  Future<CashBoxOpeningBalanceModel> setCashboxOpeningBalance({
    required SetCashBoxOpeningBalanceRequestModel body,
    String? token,
  }) async {
    log('Setting cashbox opening balance: ${body.toJson()}');

    final response = await Api().post(
      url: 'Accounting/cashbox/opening-balance',
      body: body.toJson(),
      token: token,
    );

    return CashBoxOpeningBalanceModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `POST /Accounting/cashbox/entries` — a manual cash movement.
  Future<CashBoxLedgerEntryModel> createCashboxEntry({
    required CreateCashBoxEntryRequestModel body,
    String? token,
  }) async {
    log('Creating cashbox entry: ${body.toJson()}');

    final response = await Api().post(
      url: 'Accounting/cashbox/entries',
      body: body.toJson(),
      token: token,
    );

    return CashBoxLedgerEntryModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `DELETE /Accounting/cashbox/entries/{id}` — five minutes for an ordinary
  /// user, any time for an admin. Only a manual entry has an id to pass.
  Future<void> deleteCashboxEntry({required String id, String? token}) async {
    log('Deleting cashbox entry $id');

    await Api().delete(url: 'Accounting/cashbox/entries/$id', token: token);
  }

  /// `POST /Accounting/doctors/{doctorId}/settle` — settles every outstanding
  /// invoice a doctor has **in one currency**, in one action.
  ///
  /// Per currency because money is never blended across currencies anywhere in
  /// this app; and with no receipt, because one file cannot stand for the N
  /// invoices this closes.
  Future<DoctorStatementModel> settleDoctorBalance({
    required String doctorId,
    required String currencyId,
    PaymentMethod? method,
    String? notes,
    String? token,
  }) async {
    log('Settling doctor $doctorId in currency $currencyId');

    final response = await Api().post(
      url: 'Accounting/doctors/$doctorId/settle',
      body: {
        'currencyId': currencyId,
        if (method != null) 'method': method.value,
        'notes': ?notes,
      },
      token: token,
    );

    return DoctorStatementModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /Accounting/payments/{id}` — permanent, and gated on
  /// `Finance:FullAccess` server-side.
  Future<void> deletePayment({required String id, String? token}) async {
    log('Deleting payment $id');

    await Api().delete(url: 'Accounting/payments/$id', token: token);
  }

  /// `DELETE /Accounting/invoices/{id}` — admin only, within five minutes of
  /// issue, and only while the invoice has no payments against it.
  Future<void> deleteInvoice({required String id, String? token}) async {
    log('Deleting invoice $id');

    await Api().delete(url: 'Accounting/invoices/$id', token: token);
  }

  /// `GET /Currencies` — every currency, used both by the currencies
  /// management screen and to populate every other feature's currency
  /// picker (expenses, restoration-type pricing, case restorations, ...).
  Future<List<CurrencyModel>> getCurrencies({String? token}) async {
    log('Fetching currencies');

    final responseData = await Api().get(url: 'Currencies', token: token);

    return (responseData as List<dynamic>)
        .map((e) => CurrencyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CurrencyModel> createCurrency({
    required CreateCurrencyRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create Currency request with: ${logSafe(body)}');

    final response = await Api().post(
      url: 'Currencies',
      body: body,
      token: token,
    );

    return CurrencyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CurrencyModel> updateCurrency({
    required String id,
    required UpdateCurrencyRequestModel updateRequestBody,
    String? token,
  }) async {
    final body = updateRequestBody.toJson();

    log('Sending Update Currency request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'Currencies/$id',
      body: body,
      token: token,
    );

    return CurrencyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCurrency({required String id, String? token}) async {
    log('Deleting currency: $id');

    final response = await Api().delete(url: 'Currencies/$id', token: token);

    log('Delete Currency response data: ${logSafe(response.data)}');
  }

  /// `GET /Accounting/doctors/{doctorId}/statement`.
  Future<DoctorStatementModel> getDoctorStatement({
    required String doctorId,
    String? from,
    String? to,
    String? token,
  }) async {
    log('Fetching doctor statement: $doctorId');

    final params = <String>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add('$key=${Uri.encodeQueryComponent(value)}');
      }
    }

    add('from', from);
    add('to', to);

    final url = params.isEmpty
        ? 'Accounting/doctors/$doctorId/statement'
        : 'Accounting/doctors/$doctorId/statement?${params.join('&')}';
    final responseData = await Api().get(url: url, token: token);

    return DoctorStatementModel.fromJson(responseData as Map<String, dynamic>);
  }

  /// `POST /Accounting/invoices`.
  Future<InvoiceModel> createInvoice({
    required CreateInvoiceRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create Invoice request with: ${logSafe(body)}');

    final response = await Api().post(
      url: 'Accounting/invoices',
      body: body,
      token: token,
    );

    return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /Accounting/invoices/from-case/{caseId}` — generates the case's
  /// invoice, or returns the one already generated for it (idempotent).
  Future<InvoiceModel> createInvoiceFromCase({
    required String caseId,
    double? discountValue,
    double? discountPercentage,
    String? token,
  }) async {
    log('Generating invoice for case: $caseId');

    final response = await Api().post(
      url: 'Accounting/invoices/from-case/$caseId',
      body: {
        'discountValue': discountValue,
        'discountPercentage': discountPercentage,
      },
      token: token,
    );

    return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /Reports/invoices/{id}/pdf` — raw bytes. Bypasses [Api.get]'s
  /// JSON-oriented decoding (it never sets a binary `responseType`) and goes
  /// through [Api.dio] directly instead, so the same auth interceptor still
  /// attaches the bearer token this endpoint needs.
  ///
  /// Lives under `Reports`, not `Accounting`: every printable document the API
  /// renders (the case sheet, the CSV export, this) sits on that controller,
  /// and the old `Accounting/invoices/{id}/pdf` route no longer exists.
  Future<List<int>> downloadInvoicePdf({
    required String id,
    String? token,
  }) async {
    log('Downloading invoice PDF: $id');

    final response = await Api.dio.get<List<int>>(
      'Reports/invoices/$id/pdf',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );

    return response.data ?? const [];
  }


}
