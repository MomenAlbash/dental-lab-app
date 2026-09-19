import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/accounting/data/models/doctor_statement_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/invoice_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/accounting/logic/doctor_statement/doctor_statement_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/doctor_statement/doctor_statement_state.dart';
import 'package:dental_lab_app/features/accounting/logic/payments/payments_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/payments/payments_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountingRepo extends Mock implements AccountingRepo {}

DoctorStatementModel _statement({double closing = 500}) =>
    DoctorStatementModel.fromJson({
      'doctorId': 'd1',
      'doctorName': 'د. سامر',
      'currencies': [
        {
          'currency': {'id': 'c1', 'code': 'USD'},
          'closingBalance': closing,
        },
      ],
    });

void main() {
  group('DoctorStatementCubit.settle', () {
    late _MockAccountingRepo repo;
    late DoctorStatementCubit cubit;

    setUp(() {
      repo = _MockAccountingRepo();
      when(
        () => repo.getDoctorStatement(
          doctorId: any(named: 'doctorId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, DoctorStatementModel>(_statement()),
      );

      cubit = DoctorStatementCubit(repo);
    });

    tearDown(() => cubit.close());

    test('settles one currency, never the whole account', () async {
      // A doctor can owe in two currencies and settle one of them today;
      // blending them would produce a payment against nothing.
      when(
        () => repo.settleDoctorBalance(
          doctorId: any(named: 'doctorId'),
          currencyId: any(named: 'currencyId'),
          method: any(named: 'method'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer(
        (_) async =>
            Right<Failure, DoctorStatementModel>(_statement(closing: 0)),
      );

      await cubit.getStatement('d1');
      await cubit.settle(currencyId: 'c1', method: PaymentMethod.cash);

      verify(
        () => repo.settleDoctorBalance(
          doctorId: 'd1',
          currencyId: 'c1',
          method: PaymentMethod.cash,
          notes: null,
        ),
      ).called(1);
    });

    test('takes the refreshed statement from the settle itself', () async {
      // The endpoint answers with the statement as it now stands, so asking
      // again would be a second round-trip for an answer already in hand.
      when(
        () => repo.settleDoctorBalance(
          doctorId: any(named: 'doctorId'),
          currencyId: any(named: 'currencyId'),
          method: any(named: 'method'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer(
        (_) async =>
            Right<Failure, DoctorStatementModel>(_statement(closing: 0)),
      );

      await cubit.getStatement('d1');
      await cubit.settle(currencyId: 'c1');

      final state = cubit.state as DoctorStatementLoaded;
      expect(state.statement.currencies.single.closingBalance, 0);
      verify(
        () => repo.getDoctorStatement(
          doctorId: any(named: 'doctorId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(1);
    });

    test('a refused settle leaves the statement on screen', () async {
      when(
        () => repo.settleDoctorBalance(
          doctorId: any(named: 'doctorId'),
          currencyId: any(named: 'currencyId'),
          method: any(named: 'method'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer(
        (_) async =>
            Left<Failure, DoctorStatementModel>(ServerFailure('لا مستحقات')),
      );

      await cubit.getStatement('d1');
      await cubit.settle(currencyId: 'c1');

      final state = cubit.state as DoctorStatementLoaded;
      expect(state.statement.currencies.single.closingBalance, 500);
      expect(state.isBusy, isFalse);
    });

    test('does nothing before a statement is loaded', () async {
      await cubit.settle(currencyId: 'c1');

      verifyNever(
        () => repo.settleDoctorBalance(
          doctorId: any(named: 'doctorId'),
          currencyId: any(named: 'currencyId'),
          method: any(named: 'method'),
          notes: any(named: 'notes'),
        ),
      );
    });
  });

  group('PaymentsCubit.deletePayment', () {
    late _MockAccountingRepo repo;
    late PaymentsCubit cubit;

    setUp(() {
      repo = _MockAccountingRepo();
      when(
        () => repo.getPayments(
          doctorId: any(named: 'doctorId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right<Failure, List<PaymentModel>>(const []));

      cubit = PaymentsCubit(repo);
    });

    tearDown(() => cubit.close());

    test('reloads after a delete rather than dropping the row', () async {
      // Deleting a payment reopens the invoice it was against and moves the
      // totals with it — a locally-removed row would show a list that no
      // longer adds up.
      when(
        () => repo.deletePayment(any()),
      ).thenAnswer((_) async => const Right<Failure, void>(null));

      await cubit.getPayments();
      await cubit.deletePayment('p1');

      verify(
        () => repo.getPayments(
          doctorId: any(named: 'doctorId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(2);
    });

    test('a refused delete reports the server\'s own reason', () async {
      when(() => repo.deletePayment(any())).thenAnswer(
        (_) async => Left<Failure, void>(ServerFailure('صلاحية غير كافية')),
      );

      await cubit.getPayments();

      final states = <PaymentsState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.deletePayment('p1');
      await sub.cancel();

      expect(
        states.whereType<PaymentDeleteError>().single.message,
        'صلاحية غير كافية',
      );
    });
  });

  group('InvoiceModel', () {
    test('carries the server\'s delete guard and its reason', () {
      // `canDelete` ignores who is asking — an admin may delete past the
      // window anyway — so the UI reads both this and the session.
      final invoice = InvoiceModel.fromJson({
        'id': 'i1',
        'laboratoryId': 'l1',
        'doctorId': 'd1',
        'canDelete': false,
        'deleteMessage': 'مضى أكثر من 5 دقائق على الإصدار',
      });

      expect(invoice.canDelete, isFalse);
      expect(invoice.deleteMessage, 'مضى أكثر من 5 دقائق على الإصدار');
    });

    test('an invoice with no guard fields refuses by default', () {
      final invoice = InvoiceModel.fromJson({
        'id': 'i1',
        'laboratoryId': 'l1',
        'doctorId': 'd1',
      });

      expect(invoice.canDelete, isFalse);
    });
  });
}
