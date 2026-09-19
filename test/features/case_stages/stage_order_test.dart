import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/save_case_stage_request_models.dart';
import 'package:dental_lab_app/features/case_stages/data/repos/case_stages_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

class _FakeBody extends Fake implements SaveCaseStageRequestModel {}

CaseStageModel _stage(String id, int order) =>
    CaseStageModel(id: id, name: id, nameAr: id, order: order);

void main() {
  late _MockApiService api;
  late CaseStagesRepo repo;

  setUpAll(() => registerFallbackValue(_FakeBody()));

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    api = _MockApiService();
    repo = CaseStagesRepo(api);
  });

  void stubUpdate({Exception? throws}) {
    final call = when(
      () => api.updateCaseStage(
        id: any(named: 'id'),
        body: any(named: 'body'),
        token: any(named: 'token'),
      ),
    );
    if (throws != null) {
      call.thenThrow(throws);
    } else {
      call.thenAnswer((invocation) async {
        final id = invocation.namedArguments[#id] as String;
        return _stage(id, 0);
      });
    }
  }

  test('writes the new position of every stage that moved', () async {
    // Ordering is the flow now, so this is the whole "save my workflow" path.
    stubUpdate();

    final result = await repo.saveOrder([
      _stage('b', 1),
      _stage('a', 0),
      _stage('c', 2),
    ]);

    expect(result.isRight(), isTrue);
    // 'b' moved to 0 and 'a' to 1; 'c' was already at 2.
    verify(
      () => api.updateCaseStage(
        id: 'b',
        body: any(named: 'body'),
        token: any(named: 'token'),
      ),
    ).called(1);
    verify(
      () => api.updateCaseStage(
        id: 'a',
        body: any(named: 'body'),
        token: any(named: 'token'),
      ),
    ).called(1);
    verifyNever(
      () => api.updateCaseStage(
        id: 'c',
        body: any(named: 'body'),
        token: any(named: 'token'),
      ),
    );
  });

  test('an unchanged order writes nothing at all', () async {
    stubUpdate();

    final result = await repo.saveOrder([_stage('a', 0), _stage('b', 1)]);

    expect(result.isRight(), isTrue);
    verifyNever(
      () => api.updateCaseStage(
        id: any(named: 'id'),
        body: any(named: 'body'),
        token: any(named: 'token'),
      ),
    );
  });

  test('a failure stops the run instead of half-applying an order', () async {
    // A partially written order is a workflow whose stages run in a sequence
    // nobody chose — worse than not saving at all.
    stubUpdate(
      throws: DioException(requestOptions: RequestOptions(path: '')),
    );

    final result = await repo.saveOrder([_stage('b', 1), _stage('a', 0)]);

    expect(result.isLeft(), isTrue);
    verify(
      () => api.updateCaseStage(
        id: any(named: 'id'),
        body: any(named: 'body'),
        token: any(named: 'token'),
      ),
    ).called(1);
  });

  test('resends the whole stage, since the endpoint replaces the record', () {
    // Sending only the order would blank the name, the intake and the
    // assignment on every stage that moved.
    final body = SaveCaseStageRequestModel(
      name: 'Design',
      nameAr: 'التصميم',
      order: 3,
      departmentIds: const ['d1'],
      userIds: const ['u1'],
    ).toJson();

    expect(body['name'], 'Design');
    expect(body['nameAr'], 'التصميم');
    expect(body['order'], 3);
    expect(body['departmentIds'], ['d1']);
    expect(body['userIds'], ['u1']);
  });
}
