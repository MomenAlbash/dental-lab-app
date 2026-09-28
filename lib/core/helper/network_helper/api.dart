import 'dart:developer';
import 'dart:convert';
import 'package:dental_lab_app/core/connectivity/connectivity_cubit.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/laboratory_scope.dart';
import 'package:dental_lab_app/core/helper/last_sync.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dio/dio.dart';

/// Where the API lives.
///
/// A compile-time constant rather than a literal in the transport layer: a
/// build can be pointed at another deployment without a code edit —
/// `flutter build apk --dart-define=API_ORIGIN=https://other-host`.
const String apiOrigin = String.fromEnvironment(
  'API_ORIGIN',
  defaultValue: 'https://dental-lap-api.premiumasp.net',
);

class Api {
  static late Dio dio;

  /// Invoked once for any `401` from any request.
  ///
  /// A hook rather than a direct call into the router or a cubit: this file is
  /// the transport layer and must stay free of UI and feature imports. `main`
  /// wires it to "clear the session and hard-route to login".
  static void Function()? onSessionExpired;

  /// Invoked when the server answers `laboratory_required`. A hook, like
  /// [onSessionExpired]: `main` wires it to the laboratory picker.
  static void Function()? onLaboratoryRequired;

  static DateTime? _lastLaboratoryRequired;

  /// One screen fires several requests together, and each would answer the
  /// same way — the picker opens once, not once per request.
  static void _announceLaboratoryRequired() {
    final now = DateTime.now();
    final last = _lastLaboratoryRequired;
    if (last != null && now.difference(last) < const Duration(seconds: 5)) {
      return;
    }
    _lastLaboratoryRequired = now;
    onLaboratoryRequired?.call();
  }

  static void init() {
    dio = Dio(
      BaseOptions(
        // Overridable at build time so a staging or on-prem host does not need
        // a code edit:
        //   flutter build apk --dart-define=API_ORIGIN=https://host
        baseUrl: '$apiOrigin/api/clinic/',
        receiveDataWhenStatusError: true,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Auth + laboratory scoping are injected centrally so every request
    // carries them, instead of being threaded through each call site. See
    // [LaboratoryScope] for which kind of request carries the laboratory
    // where.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = CacheHelper.getData(key: CacheKeys.token) as String?;
          if (token != null &&
              token.isNotEmpty &&
              !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // The server translates its error messages by this header alone
          // (not Accept-Language); without it they came back in English.
          options.headers['lang'] = 'ar';

          final method = options.method.toUpperCase();
          if (method == 'GET') {
            // Every selected laboratory, always — even just one. The server
            // answers 400 `laboratory_required` to a GET without it.
            final ids = LaboratoryScope.requestIds;
            if (ids.isNotEmpty) {
              options.headers['X-Laboratory-Ids'] = ids.join(',');
            }
          } else if (method == 'POST' &&
              LaboratoryScope.isCreatePath(options.path)) {
            // A create names its laboratory in the body; the header is not
            // read there. A caller that already chose one keeps it.
            // [post] sends its body already JSON-encoded, so it arrives here
            // as a string; decode it rather than miss every create.
            final raw = options.data;
            final wasEncoded = raw is String;
            final body = wasEncoded ? _tryDecodeMap(raw) : raw;
            if (body is Map<String, dynamic> && body['laboratoryId'] == null) {
              final laboratoryId = await LaboratoryScope.resolveForCreate();
              if (laboratoryId == null) {
                return handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.cancel,
                    error: 'لم يُحدَّد المخبر الذي تُضاف إليه',
                  ),
                );
              }
              final scoped = {...body, 'laboratoryId': laboratoryId};
              options.data = wasEncoded ? jsonEncode(scoped) : scoped;
            }
          }

          return handler.next(options);
        },
        // The device-level connectivity check (ConnectivityCubit) can
        // misreport on some devices/OS versions, so real request outcomes
        // are the ground truth: any response (even an error one) proves the
        // server was reachable; only an actual connectivity-type failure
        // (timeout / connection error / no route to host) means it wasn't —
        // other response-less errors (e.g. cancellation) must not flip the
        // banner, since nothing may ever call markOnline() again to correct it.
        onResponse: (response, handler) {
          getIt<ConnectivityCubit>().markOnline();
          LastSync.markNow();
          return handler.next(response);
        },
        onError: (error, handler) {
          if (error.response != null) {
            getIt<ConnectivityCubit>().markOnline();
          } else if (_isConnectivityError(error)) {
            log('Marking offline due to: ${error.type} - ${error.message}');
            getIt<ConnectivityCubit>().markOffline();
          }

          // A 401 means the token the interceptor just attached is no longer
          // accepted — expired, revoked, or issued against a database the
          // server no longer has. Every screen from here on would fail the
          // same way, so the session is dropped centrally rather than letting
          // each screen render its own "unauthorized" error. `onSessionExpired`
          // does the routing; this layer must not import UI.
          if (error.response?.statusCode == 401) {
            log('401 received — clearing the session');
            onSessionExpired?.call();
          }

          // The server's `code`, not its wording, says what went wrong. This
          // one means the request named no laboratory the user may use — the
          // answer is to pick one, not to read an error.
          final body = error.response?.data;
          if (body is Map && body['code'] == 'laboratory_required') {
            _announceLaboratoryRequired();
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Whether [error] represents a real connectivity failure (no route to
  /// the server at all) rather than some other response-less error like a
  /// cancelled request — mirrors the criteria `ServerFailure.fromDioException`
  /// already trusts for its "No Internet Connection" message.
  /// A JSON object body, or null when [raw] is anything else — a list, a
  /// bare value, or not JSON at all.
  static Map<String, dynamic>? _tryDecodeMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static bool _isConnectivityError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.unknown:
        return error.message?.contains('SocketException') ?? false;
      default:
        return false;
    }
  }

  Future<dynamic> get({required String url, String? token}) async {
    try {
      final options = Options(
        headers: {
          'accept': 'text/plain',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      log('GET Request: $url');

      Response response = await dio.get(url, options: options);
      logBody('GET Response ${response.statusCode}', response.data);
      return response.data;
    } on DioException catch (e) {
      log('DioError: ${e.message}');
      log('Status Code: ${e.response?.statusCode}');
      logBody('Response Data', e.response?.data);
      // Unwrapped the same way as post/put/delete. This used to throw a fixed
      // 'there is a problem in status Code', which meant every failed read in
      // the app reported the same unusable sentence no matter what went wrong.
      throw Exception(_readError(e));
    } catch (e) {
      log('General error in GET: $e');
      throw Exception(e.toString());
    }
  }

  Future<Response> post({
    required String url,
    required dynamic body,
    String? token,
    bool isFormData = false,
  }) async {
    try {
      return await dio.post(
        url,
        data: isFormData ? body : jsonEncode(body),
        // تأكد من ترميز البيانات كJSON
        options: Options(
          headers: {
            if (!isFormData) 'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (e) {
      log('DioError: ${e.response?.statusCode} - ${e.message}');
      logBody('Response Data', e.response?.data);
      throw Exception(_readError(e));
    }
  }

  static String _statusMessage(int status) => switch (status) {
    400 => 'الطلب غير مقبول',
    401 => 'انتهت الجلسة، الرجاء تسجيل الدخول من جديد',
    403 => 'لا تملك صلاحية لهذا الإجراء',
    404 => 'العنصر المطلوب غير موجود',
    409 => 'العملية تعارض بيانات موجودة مسبقاً',
    >= 500 => 'حدث خطأ في الخادم، حاول لاحقاً',
    _ => 'تعذّر إتمام الطلب ($status)',
  };

  /// Extracts a human-readable message from a failed request, unwrapping
  /// ASP.NET ProblemDetails (`errors` / `title`) and never returning empty.
  String _readError(DioException e) {
    final data = e.response?.data;
    final status = e.response?.statusCode;

    if (data is Map) {
      // Validation problem details: { errors: { Field: [msg, ...] }, title }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final messages = errors.values
            .expand((value) => value is List ? value : [value])
            .map((value) => value.toString())
            .where((value) => value.trim().isNotEmpty);
        if (messages.isNotEmpty) return messages.join('\n');
      }
      final message = (data['message'] ?? data['title'] ?? data['detail'])
          ?.toString();
      if (message != null && message.trim().isNotEmpty) return message;
    } else if (data is String && data.trim().isNotEmpty) {
      final text = data.trim();
      // An unhandled server exception comes back as an HTML error page. It is
      // a stack trace for a developer, not a sentence for a user, so it falls
      // through to the status-code message below.
      if (!_looksLikeHtml(text)) return text;
    }

    // Dio's own `message` is a paragraph of English for developers; the user
    // gets a sentence about what the status means instead.
    if (status != null) return _statusMessage(status);
    final fallback = e.message;
    if (fallback != null && fallback.trim().isNotEmpty) {
      return 'تعذّر إتمام الطلب، حاول مجدداً';
    }
    // No response and no message at all — almost always a transport-level
    // failure (DNS, TLS, connection refused) rather than a genuine mystery.
    // Naming the DioException type turns the next occurrence into something
    // diagnosable instead of a dead-end toast.
    return 'تعذر الاتصال بالخادم (${e.type.name})';
  }

  static bool _looksLikeHtml(String text) {
    final start = text.trimLeft().toLowerCase();
    return start.startsWith('<!doctype html') ||
        start.startsWith('<html') ||
        start.startsWith('<br') ||
        start.contains('</html>');
  }

  Future<Response> put({
    required String url,
    required dynamic body,
    String? token,
    bool isFormData = false,
  }) async {
    try {
      log('PUT Request: $url');
      logBody('PUT Body', body);

      final options = Options(
        headers: {
          'accept': '*/*',
          if (!isFormData) 'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final response = await dio.put(
        url,
        data: isFormData ? body : jsonEncode(body),
        options: options,
      );

      logBody('PUT Response ${response.statusCode}', response.data);
      return response;
    } on DioException catch (e) {
      log('DioError in PUT: ${e.message}');
      log('Status Code: ${e.response?.statusCode}');
      logBody('Response Data', e.response?.data);

      throw Exception(_readError(e));
    } catch (e) {
      log('General error in PUT: $e');
      throw Exception(e.toString());
    }
  }

  Future<Response> delete({required String url, String? token}) async {
    try {
      log('delete Request: $url');

      final options = Options(
        headers: {
          'accept': '*/*',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final response = await dio.delete(url, options: options);

      logBody('delete Response ${response.statusCode}', response.data);
      return response;
    } on DioException catch (e) {
      log('DioError in delete: ${e.message}');
      log('Status Code: ${e.response?.statusCode}');
      logBody('Response Data', e.response?.data);

      throw Exception(_readError(e));
    } catch (e) {
      log('General error in delete: $e');
      throw Exception(e.toString());
    }
  }
}
