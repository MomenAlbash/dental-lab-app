import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/users/data/models/create_user_request_model.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/data/repos/users_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

class _FakeCreateUserRequest extends Fake implements CreateUserRequestModel {}

CreateUserRequestModel _request() =>
    CreateUserRequestModel(type: 0, username: 'ahmad', password: 'secret');

void main() {
  late _MockApiService api;
  late UsersRepo repo;

  setUpAll(() {
    registerFallbackValue(_FakeCreateUserRequest());
  });

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    api = _MockApiService();
    repo = UsersRepo(api);
  });

  Future<void> signInWith({String? laboratoryId}) async {
    SharedPreferences.setMockInitialValues({
      CacheKeys.token: 'token',
      // Null-aware entry: dropped entirely when there is no laboratory.
      CacheKeys.laboratoryId: ?laboratoryId,
    });
    await CacheHelper.init();
  }

  test('creates the user when the session has a laboratory', () async {
    await signInWith(laboratoryId: 'lab-1');
    when(
      () => api.createUser(
        createUserRequestBody: any(named: 'createUserRequestBody'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => UserModel(id: 'u1', username: 'ahmad'));

    final result = await repo.createUser(_request());

    expect(result.isRight(), isTrue);
    verify(
      () => api.createUser(
        createUserRequestBody: any(named: 'createUserRequestBody'),
        token: any(named: 'token'),
      ),
    ).called(1);
  });

  test('refuses to create a user with no laboratory in the session', () async {
    // The request would otherwise go out with no X-Laboratory-Id header and
    // create an unscoped account — wrong silently instead of refused loudly.
    await signInWith();

    final result = await repo.createUser(_request());

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => api.createUser(
        createUserRequestBody: any(named: 'createUserRequestBody'),
        token: any(named: 'token'),
      ),
    );
  });

  test('treats an empty laboratory id as no laboratory', () async {
    await signInWith(laboratoryId: '');

    final result = await repo.createUser(_request());

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => api.createUser(
        createUserRequestBody: any(named: 'createUserRequestBody'),
        token: any(named: 'token'),
      ),
    );
  });
}
