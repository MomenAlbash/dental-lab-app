import 'package:dio/dio.dart';

abstract class Failure {
  final String errorMessage;

  Failure(this.errorMessage);
}

class ServerFailure extends Failure {
  ServerFailure(super.errorMessage);

  /// [Api] wraps transport errors in a plain `Exception` whose message is the
  /// server's own text, so unwrap it instead of showing `Exception: ...` to
  /// the user.
  factory ServerFailure.fromException(Object error) {
    final message = error.toString().replaceFirst(
      RegExp(r'^Exception:\s*'),
      '',
    );
    return ServerFailure(
      message.isEmpty
          ? 'Oops , there was an error , Please try again'
          : message,
    );
  }

  factory ServerFailure.FromDioExecption(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return ServerFailure('Connection timeout with ApiServer');
      case DioExceptionType.sendTimeout:
        // TODO: Handle this case.
        return ServerFailure('Send timeout with ApiServer');
      case DioExceptionType.receiveTimeout:
        // TODO: Handle this case.
        return ServerFailure('Receive timeout with ApiServer');
      case DioExceptionType.badCertificate:
        // TODO: Handle this case.
        return ServerFailure('badCertificate  with ApiServer');
      case DioExceptionType.badResponse:
        return ServerFailure.FromRespone(
          dioException.response!.statusCode ?? 405,
          dioException.response,
        );
      case DioExceptionType.cancel:
        return ServerFailure('Request From ApiServer was cancelled');
      case DioExceptionType.connectionError:
        return ServerFailure('Connection Error with Api');
      case DioExceptionType.unknown:
        if (dioException.message!.contains('SocketException')) {
          return ServerFailure('No Internet Connection');
        } else {
          return ServerFailure('UnExpected Error , Please try later');
        }

      default:
        return ServerFailure('Oops , there was an error , try later');
    }
  }
  factory ServerFailure.FromRespone(int statusCode, dynamic response) {
    if (statusCode == 400 ||
        statusCode == 401 ||
        statusCode == 403 ||
        statusCode == 409) {
      return ServerFailure(response['message']);
    } else if (statusCode == 404) {
      return ServerFailure('Your Request not found , Please try later');
    } else if (statusCode == 500) {
      return ServerFailure('Internal Server Error , Please try later');
    } else {
      return ServerFailure('Oops , there was an error , Please try again');
    }
  }
}
