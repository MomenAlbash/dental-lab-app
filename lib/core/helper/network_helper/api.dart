import 'dart:developer';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class Api {
  static late Dio dio;

  static init() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://givechain.runasp.net/api/mobile/',
        receiveDataWhenStatusError: true,
        headers: {'Content-Type': 'application/json'},
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
      log('DioError: ${e.response?.data ?? e.message}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map
            ? errorData['title'] ?? errorData.toString()
            : errorData.toString();

        throw Exception(errorMessage);
      }

      throw Exception(e.message);
    }
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
