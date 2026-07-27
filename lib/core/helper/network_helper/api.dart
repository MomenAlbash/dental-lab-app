import 'dart:developer';
import 'dart:convert';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class Api {
  static late Dio dio;

  static init() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://dental-lab.runasp.net/api/clinic/',
        receiveDataWhenStatusError: true,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Auth + laboratory scoping are injected centrally so every request
    // carries them, instead of being threaded through each call site. The
    // whole app is scoped to the active laboratory via the `X-Laboratory-Id`
    // header, alongside the bearer token.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = CacheHelper.getData(key: CacheKeys.token) as String?;
          if (token != null &&
              token.isNotEmpty &&
              !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          final laboratoryId =
              CacheHelper.getData(key: CacheKeys.laboratoryId) as String?;
          if (laboratoryId != null && laboratoryId.isNotEmpty) {
            options.headers['X-Laboratory-Id'] = laboratoryId;
          }

          return handler.next(options);
        },
      ),
    );
  }

  Future<dynamic> get({required String Url, @required String? token}) async {
    try {
      final options = Options(
        headers: {
          'accept': 'text/plain',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      log('GET Request: $Url');
      if (token != null) log('Token: $token');

      Response response = await dio.get(Url, options: options);
      log('GET Response: ${response.statusCode} - ${response.data}');
      return response.data;
    } on DioException catch (e) {
      log('DioError: ${e.message}');
      log('Status Code: ${e.response?.statusCode}');
      log('Response Data: ${e.response?.data}');
      throw Exception('there is a problem in status Code');
    } catch (e) {
      throw Exception("there is an error");
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
      log('DioError: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      throw Exception(_readError(e));
    }
  }

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
      return data;
    }

    final fallback = e.message;
    if (fallback != null && fallback.trim().isNotEmpty) {
      return status != null ? '$fallback (HTTP $status)' : fallback;
    }
    return status != null ? 'خطأ من الخادم (HTTP $status)' : 'خطأ غير متوقع';
  }

  Future<Response> put({
    required String url,
    required dynamic body,
    String? token,
    bool isFormData = false,
  }) async {
    try {
      log('PUT Request: $url');
      log('PUT Body: $body');
      if (token != null) log('Token: $token');

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

      log('PUT Response: ${response.statusCode} - ${response.data}');
      return response;
    } on DioException catch (e) {
      log('DioError in PUT: ${e.message}');
      log('Status Code: ${e.response?.statusCode}');
      log('Response Data: ${e.response?.data}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map
            ? errorData['title'] ?? errorData.toString()
            : errorData.toString();
        throw Exception(errorMessage);
      }
      throw Exception(e.message ?? 'Unknown error in PUT request');
    } catch (e) {
      log('General error in PUT: $e');
      throw Exception(e.toString());
    }
  }

  Future<Response> delete({required String url, String? token}) async {
    try {
      log('delete Request: $url');
      if (token != null) log('Token: $token');

      final options = Options(
        headers: {
          'accept': '*/*',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final response = await dio.delete(url, options: options);

      log('delete Response: ${response.statusCode} - ${response.data}');
      return response;
    } on DioException catch (e) {
      log('DioError in delete: ${e.message}');
      log('Status Code: ${e.response?.statusCode}');
      log('Response Data: ${e.response?.data}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map
            ? errorData['title'] ?? errorData.toString()
            : errorData.toString();
        throw Exception(errorMessage);
      }
      throw Exception(e.message ?? 'Unknown error in PUT request');
    } catch (e) {
      log('General error in PUT: $e');
      throw Exception(e.toString());
    }
  }
}
