import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_file_model.dart';
import 'package:dental_lab_app/features/cases/data/models/create_case_request_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCasesRepo extends Mock implements CasesRepo {}

final _requestBody = CreateCaseRequestModel();
final _caseDetail = CaseDetailModel.fromJson(const {'id': 'c1'});

void main() {
  setUpAll(() {
    registerFallbackValue(_requestBody);
  });

  late MockCasesRepo repo;
  late CaseFormCubit cubit;

  setUp(() {
    repo = MockCasesRepo();
    cubit = CaseFormCubit(repo);
  });

  tearDown(() => cubit.close());

  test(
    'a case with no attachments reports success with nothing to upload',
    () async {
      when(
        () => repo.createCase(any()),
      ).thenAnswer((_) async => right(_caseDetail));

      await cubit.createCase(_requestBody);

      final state = cubit.state as CaseFormSuccess;
      expect(state.failedAttachmentCount, 0);
      expect(state.attachmentFailed, isFalse);
      verifyNever(
        () => repo.uploadFile(
          id: any(named: 'id'),
          filePath: any(named: 'filePath'),
        ),
      );
    },
  );

  test('uploads every picked file once the case exists', () async {
    when(
      () => repo.createCase(any()),
    ).thenAnswer((_) async => right(_caseDetail));
    when(
      () => repo.uploadFile(
        id: any(named: 'id'),
        filePath: any(named: 'filePath'),
      ),
    ).thenAnswer((_) async => right(CaseFileModel(id: 'f1')));

    await cubit.createCase(
      _requestBody,
      attachmentPaths: ['a.jpg', 'b.pdf', 'c.png'],
    );

    final state = cubit.state as CaseFormSuccess;
    expect(state.failedAttachmentCount, 0);
    verify(() => repo.uploadFile(id: 'c1', filePath: 'a.jpg')).called(1);
    verify(() => repo.uploadFile(id: 'c1', filePath: 'b.pdf')).called(1);
    verify(() => repo.uploadFile(id: 'c1', filePath: 'c.png')).called(1);
  });

  test('the case is still reported saved when some attachments fail', () async {
    // The case is the one thing here that cannot be re-entered by hand, so
    // a bad file must never take it down with it.
    when(
      () => repo.createCase(any()),
    ).thenAnswer((_) async => right(_caseDetail));
    var call = 0;
    when(
      () => repo.uploadFile(
        id: any(named: 'id'),
        filePath: any(named: 'filePath'),
      ),
    ).thenAnswer((_) async {
      call++;
      // The second file fails, the other two succeed.
      return call == 2
          ? left(ServerFailure('رُفض'))
          : right(CaseFileModel(id: 'f1'));
    });

    await cubit.createCase(
      _requestBody,
      attachmentPaths: ['a.jpg', 'b.jpg', 'c.jpg'],
    );

    final state = cubit.state as CaseFormSuccess;
    expect(state.caseDetail.id, 'c1');
    expect(state.failedAttachmentCount, 1);
    expect(state.attachmentFailed, isTrue);
  });

  test('a failed case creation never attempts an upload', () async {
    when(
      () => repo.createCase(any()),
    ).thenAnswer((_) async => left(ServerFailure('مرفوض')));

    await cubit.createCase(_requestBody, attachmentPaths: ['a.jpg']);

    expect(cubit.state, isA<CaseFormError>());
    verifyNever(
      () => repo.uploadFile(
        id: any(named: 'id'),
        filePath: any(named: 'filePath'),
      ),
    );
  });
}
