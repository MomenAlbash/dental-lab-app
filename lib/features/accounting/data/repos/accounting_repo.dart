import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/accounting/data/models/accounting_statistics_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/cashbox_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/create_invoice_request_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/doctor_statement_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/expense_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/invoice_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AccountingRepo {
  final ApiService _apiService;
  AccountingRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  /// The try/catch every one-line call below shares. The older methods in this
  /// file each spell it out; new ones go through here rather than adding a
  /// fourth copy of the same eight lines.
  Future<Either<Failure, T>> _guard<T>(
    String what,
    Future<T> Function() request,
  ) async {
    try {
      return right(await request());
    } on DioException catch (e) {
      log('DioException while $what: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while $what: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  // ---- Cash box --------------------------------------------------------

  /// One ledger per currency — never one blended total. Two currencies in the
  /// same drawer are two boxes, and their sum is true of nothing.
  Future<Either<Failure, List<CashBoxLedgerModel>>> getCashboxLedger({
    DateTime? from,
    DateTime? to,
  }) => _guard(
    'fetching the cashbox ledger',
    () => _apiService.getCashboxLedger(
      from: from == null ? null : ApiTime.formatDate(from),
      to: to == null ? null : ApiTime.formatDate(to),
      token: _token,
    ),
  );

  Future<Either<Failure, List<CashBoxOpeningBalanceModel>>>
  getCashboxOpeningBalances() => _guard(
    'fetching cashbox opening balances',
    () => _apiService.getCashboxOpeningBalances(token: _token),
  );

  Future<Either<Failure, CashBoxOpeningBalanceModel>> setCashboxOpeningBalance(
    SetCashBoxOpeningBalanceRequestModel body,
  ) => _guard(
    'setting the cashbox opening balance',
    () => _apiService.setCashboxOpeningBalance(body: body, token: _token),
  );

  Future<Either<Failure, CashBoxLedgerEntryModel>> createCashboxEntry(
    CreateCashBoxEntryRequestModel body,
  ) => _guard(
    'recording a cashbox entry',
    () => _apiService.createCashboxEntry(body: body, token: _token),
  );

  /// Deletable within five minutes for an ordinary user, any time for an
  /// admin — and only ever a *manual* entry: a payment or expense line is
  /// managed from its own screen.
  Future<Either<Failure, void>> deleteCashboxEntry(String id) => _guard(
    'deleting a cashbox entry',
    () => _apiService.deleteCashboxEntry(id: id, token: _token),
  );

  /// Closes every outstanding invoice a doctor has in one currency at once.
  Future<Either<Failure, DoctorStatementModel>> settleDoctorBalance({
    required String doctorId,
    required String currencyId,
    PaymentMethod? method,
    String? notes,
  }) => _guard(
    'settling the doctor balance',
    () => _apiService.settleDoctorBalance(
      doctorId: doctorId,
      currencyId: currencyId,
      method: method,
      notes: notes,
      token: _token,
    ),
  );

  Future<Either<Failure, void>> deletePayment(String id) => _guard(
    'deleting a payment',
    () => _apiService.deletePayment(id: id, token: _token),
  );

  /// Admin only, within five minutes of issue, and only while nothing has been
  /// paid against it — all three enforced by the server, which is why the
  /// failure message is shown as it comes back rather than rewritten.
  Future<Either<Failure, void>> deleteInvoice(String id) => _guard(
    'deleting an invoice',
    () => _apiService.deleteInvoice(id: id, token: _token),
  );

  Future<Either<Failure, List<InvoiceModel>>> getInvoices({
    String? doctorId,
    String? from,
    String? to,
    InvoiceStatus? status,
    String? search,
  }) async {
    try {
      final invoices = await _apiService.getInvoices(
        doctorId: doctorId,
        from: from,
        to: to,
        status: status,
        search: search,
        token: _token,
      );

      log('Fetched ${invoices.length} invoices');
      return right(invoices);
    } on DioException catch (e) {
      log('DioException while fetching invoices: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching invoices: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, InvoiceModel>> getInvoiceById(String id) async {
    try {
      final invoice = await _apiService.getInvoiceById(id: id, token: _token);

      log('Fetched invoice: ${invoice.invoiceNumber}');
      return right(invoice);
    } on DioException catch (e) {
      log('DioException while fetching invoice: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching invoice: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, AccountingStatisticsModel>> getStatistics({
    String? doctorId,
    String? from,
    String? to,
  }) async {
    try {
      final statistics = await _apiService.getAccountingStatistics(
        doctorId: doctorId,
        from: from,
        to: to,
        token: _token,
      );

      log('Fetched accounting statistics');
      return right(statistics);
    } on DioException catch (e) {
      log('DioException while fetching accounting statistics: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching accounting statistics: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, List<PaymentModel>>> getPayments({
    String? doctorId,
    String? from,
    String? to,
  }) async {
    try {
      final payments = await _apiService.getPayments(
        doctorId: doctorId,
        from: from,
        to: to,
        token: _token,
      );

      log('Fetched ${payments.length} payments');
      return right(payments);
    } on DioException catch (e) {
      log('DioException while fetching payments: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching payments: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, List<PaymentModel>>> getPendingPayments() async {
    try {
      final payments = await _apiService.getPendingPayments(token: _token);

      log('Fetched ${payments.length} pending payments');
      return right(payments);
    } on DioException catch (e) {
      log('DioException while fetching pending payments: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching pending payments: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, PaymentModel>> verifyPayment({
    required String id,
    required bool approve,
    String? notes,
  }) async {
    try {
      final payment = await _apiService.verifyPayment(
        id: id,
        approve: approve,
        notes: notes,
        token: _token,
      );

      log('Verified payment $id (approve: $approve)');
      return right(payment);
    } on DioException catch (e) {
      log('DioException while verifying payment: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while verifying payment: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, PaymentModel>> createManualPayment({
    required String invoiceId,
    required String doctorId,
    required double amount,
    PaymentMethod? method,
    String? notes,
    String? receiptFilePath,
  }) async {
    try {
      final payment = await _apiService.createManualPayment(
        invoiceId: invoiceId,
        doctorId: doctorId,
        amount: amount,
        method: method,
        notes: notes,
        receiptFilePath: receiptFilePath,
        token: _token,
      );

      log('Recorded manual payment for invoice $invoiceId');
      return right(payment);
    } on DioException catch (e) {
      log('DioException while recording manual payment: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while recording manual payment: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, List<ExpenseModel>>> getExpenses() async {
    try {
      final expenses = await _apiService.getExpenses(token: _token);

      log('Fetched ${expenses.length} expenses');
      return right(expenses);
    } on DioException catch (e) {
      log('DioException while fetching expenses: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching expenses: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, ExpenseModel>> createExpense(
    CreateExpenseRequestModel requestBody,
  ) async {
    try {
      final expense = await _apiService.createExpense(
        createRequestBody: requestBody,
        token: _token,
      );

      log('Created expense: ${expense.category}');
      return right(expense);
    } on DioException catch (e) {
      log('DioException while creating expense: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while creating expense: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, List<CurrencyModel>>> getCurrencies() async {
    try {
      final currencies = await _apiService.getCurrencies(token: _token);

      log('Fetched ${currencies.length} currencies');
      return right(currencies);
    } on DioException catch (e) {
      log('DioException while fetching currencies: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching currencies: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, DoctorStatementModel>> getDoctorStatement({
    required String doctorId,
    String? from,
    String? to,
  }) async {
    try {
      final statement = await _apiService.getDoctorStatement(
        doctorId: doctorId,
        from: from,
        to: to,
        token: _token,
      );

      log('Fetched statement for doctor: $doctorId');
      return right(statement);
    } on DioException catch (e) {
      log('DioException while fetching doctor statement: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching doctor statement: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, InvoiceModel>> createInvoice(
    CreateInvoiceRequestModel requestBody,
  ) async {
    try {
      final invoice = await _apiService.createInvoice(
        createRequestBody: requestBody,
        token: _token,
      );

      log('Created invoice: ${invoice.invoiceNumber}');
      return right(invoice);
    } on DioException catch (e) {
      log('DioException while creating invoice: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while creating invoice: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, InvoiceModel>> createInvoiceFromCase({
    required String caseId,
    double? discountValue,
    double? discountPercentage,
  }) async {
    try {
      final invoice = await _apiService.createInvoiceFromCase(
        caseId: caseId,
        discountValue: discountValue,
        discountPercentage: discountPercentage,
        token: _token,
      );

      log('Generated invoice for case: $caseId');
      return right(invoice);
    } on DioException catch (e) {
      log('DioException while generating invoice from case: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while generating invoice from case: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Downloads the invoice's PDF and saves it to a temp file — the endpoint
  /// needs the bearer token, so it cannot just be opened as a bare URL the
  /// way an already-uploaded attachment is.
  Future<Either<Failure, String>> downloadInvoicePdf({
    required String id,
    required String invoiceNumber,
  }) async {
    try {
      final bytes = await _apiService.downloadInvoicePdf(id: id, token: _token);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/invoice-$invoiceNumber.pdf');
      await file.writeAsBytes(bytes, flush: true);

      log('Saved invoice PDF to ${file.path}');
      return right(file.path);
    } on DioException catch (e) {
      log('DioException while downloading invoice PDF: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while downloading invoice PDF: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
