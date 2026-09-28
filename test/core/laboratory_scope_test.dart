import 'dart:convert';

import 'package:dental_lab_app/core/connectivity/connectivity_cubit.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/laboratory_scope.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records the request the interceptors let through, then fails it without a
/// response — so nothing downstream (the connectivity banner) is touched.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    throw StateError('captured');
  }

  @override
  void close({bool force = false}) {}
}

const _labA = (id: 'a1', name: 'المخبر أ');
const _labB = (id: 'b2', name: 'المخبر ب');

void main() {
  late _CapturingAdapter adapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    Api.init();
    adapter = _CapturingAdapter();
    Api.dio.httpClientAdapter = adapter;
    LaboratoryScope.chooseForCreate = null;
  });

  Future<RequestOptions> send(String method, String path, [Object? body]) {
    return Api.dio
        .request<dynamic>(
          path,
          data: body,
          options: Options(method: method),
        )
        .then<RequestOptions>((_) => adapter.last!)
        .catchError((Object _) => adapter.last!);
  }

  group('LaboratoryScope', () {
    test(
      'keeps every selected laboratory, first also as the old key',
      () async {
        await LaboratoryScope.save([_labA, _labB]);

        expect(LaboratoryScope.ids, ['a1', 'b2']);
        expect(LaboratoryScope.isMulti, isTrue);
        expect(CacheHelper.getData(key: CacheKeys.laboratoryId), 'a1');
        expect(LaboratoryScope.laboratories.last.name, 'المخبر ب');
      },
    );

    test('a session saved before multi-scope still has its laboratory', () {
      SharedPreferences.setMockInitialValues({CacheKeys.laboratoryId: 'old'});

      return CacheHelper.init().then((_) {
        expect(LaboratoryScope.ids, ['old']);
      });
    });

    test('knows the create endpoints and nothing else', () {
      expect(LaboratoryScope.isCreatePath('Cases'), isTrue);
      expect(LaboratoryScope.isCreatePath('/cases?x=1'), isTrue);
      expect(
        LaboratoryScope.isCreatePath('Community/doctors/d1/follow'),
        isTrue,
      );
      // Actions on an existing row read its own laboratory.
      expect(LaboratoryScope.isCreatePath('Cases/c1/trying/reject'), isFalse);
      expect(LaboratoryScope.isCreatePath('Cases/deliver-directly'), isFalse);
    });

    test('one laboratory needs no question', () async {
      await LaboratoryScope.save([_labA]);
      LaboratoryScope.chooseForCreate = (_) async => fail('asked');

      expect(await LaboratoryScope.resolveForCreate(), 'a1');
    });

    test('several ask the user', () async {
      await LaboratoryScope.save([_labA, _labB]);
      LaboratoryScope.chooseForCreate = (options) async => options.last.id;

      expect(await LaboratoryScope.resolveForCreate(), 'b2');
    });
  });

  group('the request interceptor', () {
    test(
      'a GET carries every selected laboratory in the plural header',
      () async {
        // The bug this fixes: the server only reads `X-Laboratory-Ids`, so the
        // old singular header left every GET unscoped — 400 on the dashboard.
        await LaboratoryScope.save([_labA, _labB]);

        final sent = await send('GET', 'Dashboard/summary');

        expect(sent.headers['X-Laboratory-Ids'], 'a1,b2');
        expect(sent.headers.containsKey('X-Laboratory-Id'), isFalse);
      },
    );

    test('a create gets its laboratory in the body', () async {
      await LaboratoryScope.save([_labA]);

      final sent = await send(
        'POST',
        'Patients',
        jsonEncode({'firstName': 'x'}),
      );

      final body = jsonDecode(sent.data as String) as Map<String, dynamic>;
      expect(body['laboratoryId'], 'a1');
      expect(body['firstName'], 'x');
    });

    test('with several laboratories a create uses the one picked', () async {
      await LaboratoryScope.save([_labA, _labB]);
      LaboratoryScope.chooseForCreate = (_) async => 'b2';

      final sent = await send(
        'POST',
        'Doctors',
        jsonEncode({'firstName': 'x'}),
      );

      final body = jsonDecode(sent.data as String) as Map<String, dynamic>;
      expect(body['laboratoryId'], 'b2');
    });

    test('a laboratory the caller already chose is kept', () async {
      await LaboratoryScope.save([_labA, _labB]);
      LaboratoryScope.chooseForCreate = (_) async => fail('asked');

      final sent = await send(
        'POST',
        'Zones',
        jsonEncode({'name': 'z', 'laboratoryId': 'b2'}),
      );

      expect((jsonDecode(sent.data as String) as Map)['laboratoryId'], 'b2');
    });

    test('a cancelled pick sends nothing', () async {
      await LaboratoryScope.save([_labA, _labB]);
      LaboratoryScope.chooseForCreate = (_) async => null;

      await expectLater(
        Api.dio.post<dynamic>('Cases', data: jsonEncode({'x': 1})),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(adapter.last, isNull);
    });

    test('an action on an existing row gets no laboratory', () async {
      await LaboratoryScope.save([_labA]);

      final sent = await send(
        'POST',
        'Cases/c1/trying/reject',
        jsonEncode({'note': 'n'}),
      );

      expect(
        (jsonDecode(sent.data as String) as Map).containsKey('laboratoryId'),
        isFalse,
      );
    });
  });

  group('a create form pinned to one laboratory', () {
    setUp(() => LaboratoryScope.save([_labA, _labB]));

    test('its pickers read only that laboratory', () async {
      final sent = await LaboratoryScope.runPinned(
        'b2',
        () => send('GET', 'Doctors'),
      );

      expect(sent.headers['X-Laboratory-Ids'], 'b2');
    });

    test('saving goes there without asking again', () async {
      LaboratoryScope.chooseForCreate = (_) async => fail('asked twice');

      final sent = await LaboratoryScope.runPinned(
        'b2',
        () => send('POST', 'Cases', jsonEncode({'x': 1})),
      );

      expect((jsonDecode(sent.data as String) as Map)['laboratoryId'], 'b2');
    });

    test('closing the form brings back every selected laboratory', () async {
      await LaboratoryScope.runPinned('b2', () async {});

      final sent = await send('GET', 'Doctors');
      expect(sent.headers['X-Laboratory-Ids'], 'a1,b2');
      expect(LaboratoryScope.pinned, isNull);
    });

    test('the pin is released even if the form fails', () async {
      await expectLater(
        LaboratoryScope.runPinned('b2', () async => throw StateError('x')),
        throwsStateError,
      );

      expect(LaboratoryScope.pinned, isNull);
    });
  });
  group('errors', () {
    /// Answers every request with [status] and [body], the way the server
    /// reports a refusal.
    void answer(int status, Map<String, dynamic>? body) {
      Api.dio.httpClientAdapter = _AnsweringAdapter(status, body);
    }

    setUp(() async {
      await getIt.reset();
      getIt.registerLazySingleton<ConnectivityCubit>(ConnectivityCubit.new);
      Api.onLaboratoryRequired = null;
    });

    tearDown(() async {
      Api.onLaboratoryRequired = null;
      await getIt.reset();
    });

    test('every request asks for Arabic messages', () async {
      // Without it the server answered in English.
      await LaboratoryScope.save([_labA]);

      final sent = await send('GET', 'Dashboard/summary');

      expect(sent.headers['lang'], 'ar');
    });

    test(
      '"laboratory_required" opens the picker once, not per request',
      () async {
        var opened = 0;
        Api.onLaboratoryRequired = () => opened++;
        answer(400, {
          'message': 'يجب اختيار مخبر',
          'code': 'laboratory_required',
        });

        for (final path in ['Dashboard/summary', 'Cases', 'Doctors']) {
          await Api.dio
              .get<dynamic>(path)
              .catchError(
                (_) => Response<dynamic>(
                  requestOptions: RequestOptions(path: path),
                ),
              );
        }

        expect(opened, 1);
      },
    );

    test(
      'a refusal with no reason reads as Arabic, not Dio\'s English',
      () async {
        answer(403, null);

        await expectLater(
          Api().get(url: 'Doctors'),
          throwsA(
            predicate(
              (e) => e.toString().contains('لا تملك صلاحية لهذا الإجراء'),
            ),
          ),
        );
      },
    );
  });
}

/// Answers with a fixed status and JSON body.
class _AnsweringAdapter implements HttpClientAdapter {
  _AnsweringAdapter(this.status, this.body);

  final int status;
  final Map<String, dynamic>? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
