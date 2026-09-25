import 'package:dio/dio.dart';

abstract class Failure {
  final String errorMessage;

  /// The HTTP status the server answered with, when there was one. Null for
  /// transport failures (no response) and for locally-raised failures.
  ///
  /// Carried because some refusals are a normal outcome rather than an error:
  /// a `403` on a restoration stage move means "this stage is not yours", the
  /// one thing the API says about work assignment, and a caller that can only
  /// see the message string has to match on Arabic text to tell it apart.
  final int? statusCode;

  Failure(this.errorMessage, {this.statusCode});
}

class ServerFailure extends Failure {
  ServerFailure(super.errorMessage, {super.statusCode});

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

  factory ServerFailure.fromDioException(DioException dioException) {
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
        return ServerFailure.fromResponse(
          dioException.response!.statusCode ?? 405,
          // The decoded body, not the `Response` wrapper. `Response` has no
          // `operator []`, so passing it made every 400/401/403/409 throw a
          // NoSuchMethodError instead of showing the server's reason — the
          // one case where the server has actually told us what is wrong.
          dioException.response?.data,
        );
      case DioExceptionType.cancel:
        // A request the app itself stopped carries its reason as the error —
        // e.g. no laboratory picked for a create — and that is what to show.
        final reason = dioException.error;
        if (reason is String && reason.isNotEmpty) return ServerFailure(reason);
        return ServerFailure('Request From ApiServer was cancelled');
      case DioExceptionType.connectionError:
        return ServerFailure('Connection Error with Api');
      case DioExceptionType.unknown:
        // Null-safe: an unknown-type DioException can carry no message at all,
        // and dereferencing it threw a null-check error out of the very code
        // meant to turn an error into a readable failure.
        if (dioException.message?.contains('SocketException') ?? false) {
          return ServerFailure('No Internet Connection');
        } else {
          return ServerFailure('UnExpected Error , Please try later');
        }

      default:
        return ServerFailure('Oops , there was an error , try later');
    }
  }

  /// Digs the server's own reason out of an error body.
  ///
  /// ASP.NET answers in more than one shape — a bare `message`, a `title`, a
  /// `detail`, a ProblemDetails `errors` map of field → messages, or a plain
  /// string — and a rejection the user cannot read is a rejection they cannot
  /// act on. Falls back to naming the status rather than to an empty toast.
  static String _messageOf(dynamic body, int statusCode) {
    if (body is String && body.trim().isNotEmpty) return body.trim();

    if (body is Map) {
      for (final key in ['message', 'detail', 'title', 'error']) {
        final value = body[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }

      final errors = body['errors'];
      if (errors is Map) {
        final messages = [
          for (final entry in errors.values)
            if (entry is List)
              ...entry.whereType<String>()
            else if (entry is String)
              entry,
        ];
        if (messages.isNotEmpty) return messages.join('\n');
      }
    }

    return switch (statusCode) {
      401 => 'انتهت الجلسة، الرجاء تسجيل الدخول من جديد',
      403 => 'لا تملك صلاحية لهذا الإجراء',
      409 => 'العملية تعارض بيانات موجودة مسبقاً',
      _ => 'الطلب غير مقبول',
    };
  }

  factory ServerFailure.fromResponse(int statusCode, dynamic response) {
    if (statusCode == 400 ||
        statusCode == 401 ||
        statusCode == 403 ||
        statusCode == 409) {
      return ServerFailure(
        _messageOf(response, statusCode),
        statusCode: statusCode,
      );
    } else if (statusCode == 404) {
      return ServerFailure(
        'Your Request not found , Please try later',
        statusCode: statusCode,
      );
    } else if (statusCode == 500) {
      return ServerFailure(
        'Internal Server Error , Please try later',
        statusCode: statusCode,
      );
    } else {
      return ServerFailure(
        'Oops , there was an error , Please try again',
        statusCode: statusCode,
      );
    }
  }
}
