import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/cases/data/models/case_barcode_models.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/barcode_scan/barcode_scan_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/barcode_scan/barcode_scan_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCasesRepo extends Mock implements CasesRepo {}

final _case = CaseDetailModel.fromJson(const {
  'id': 'case-1',
  'caseNumber': 'C-100',
});

void main() {
  late _MockCasesRepo repo;
  late BarcodeScanCubit cubit;

  setUp(() {
    repo = _MockCasesRepo();
    cubit = BarcodeScanCubit(repo);
  });

  tearDown(() => cubit.close());

  void stubRestoration(String code, ScannedRestorationModel? answer) {
    when(() => repo.getRestorationByNumber(code)).thenAnswer(
      (_) async =>
          answer == null ? left(ServerFailure('not found')) : right(answer),
    );
  }

  void stubCase(String code, CaseDetailModel? answer) {
    when(() => repo.getCaseByNumber(code)).thenAnswer(
      (_) async =>
          answer == null ? left(ServerFailure('not found')) : right(answer),
    );
  }

  test('a restoration barcode reports the piece and its case', () async {
    // The piece on the bench is what gets scanned, and the technician needs
    // the case it belongs to — the API answers with both.
    stubRestoration(
      'R-7',
      ScannedRestorationModel(
        restorationId: 'rest-1',
        restorationNumber: 'R-7',
        caseDetail: _case,
      ),
    );

    await cubit.resolve('R-7');

    final state = cubit.state;
    expect(state, isA<BarcodeScanRestorationFound>());
    expect((state as BarcodeScanRestorationFound).restorationId, 'rest-1');
    expect(state.caseDetail.id, 'case-1');
    // The case lookup is never reached: the first answer already had it.
    verifyNever(() => repo.getCaseByNumber(any()));
  });

  test('a case barcode falls through to the case lookup', () async {
    stubRestoration('C-100', null);
    stubCase('C-100', _case);

    await cubit.resolve('C-100');

    expect(cubit.state, isA<BarcodeScanCaseFound>());
    expect((cubit.state as BarcodeScanCaseFound).caseDetail.id, 'case-1');
  });

  test('an unknown code is reported with the code itself', () async {
    // "not found" about nothing in particular is not something a user can act
    // on — a sticker from another lab and an unreadable one look the same.
    stubRestoration('X-1', null);
    stubCase('X-1', null);

    await cubit.resolve('X-1');

    expect(cubit.state, isA<BarcodeScanNotFound>());
    expect((cubit.state as BarcodeScanNotFound).code, 'X-1');
  });

  test('the same code arriving repeatedly is resolved once', () async {
    // The camera reports a code many times a second; without this the app
    // would fire a lookup per frame.
    stubRestoration('C-100', null);
    stubCase('C-100', _case);

    await cubit.resolve('C-100');
    await cubit.resolve('C-100');

    verify(() => repo.getCaseByNumber('C-100')).called(1);
  });

  test('a blank read is ignored', () async {
    await cubit.resolve('   ');

    expect(cubit.state, isA<BarcodeScanIdle>());
    verifyNever(() => repo.getRestorationByNumber(any()));
  });

  test('reset lets the same sticker be scanned again', () async {
    stubRestoration('C-100', null);
    stubCase('C-100', _case);

    await cubit.resolve('C-100');
    cubit.reset();
    await cubit.resolve('C-100');

    verify(() => repo.getCaseByNumber('C-100')).called(2);
  });

  group('CasePrintTicketModel', () {
    test('reads the payload and the per-restoration numbers', () {
      final ticket = CasePrintTicketModel.fromJson(const {
        'caseNumber': 'C-100',
        'qrPayload': 'CASE|C-100',
        'restorations': [
          {'restorationNumber': 'R-7', 'typeNameAr': 'زيركون', 'quantity': 2},
        ],
      });

      expect(ticket.qrPayload, 'CASE|C-100');
      expect(ticket.restorations.single.restorationNumber, 'R-7');
      expect(ticket.restorations.single.displayName, 'زيركون');
    });
  });
}
