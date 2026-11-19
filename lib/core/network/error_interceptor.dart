import 'package:dio/dio.dart';
import '../error/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw ServerException('Request timed out: Server took too long to respond.', 408);

      case DioExceptionType.connectionError:
        throw const NetworkException('Unable to reach server. Please check your network connection.');

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final responseData = err.response?.data;
        String errorMessage = 'Unexpected server response';

        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message']?.toString() ??
              responseData['error']?.toString() ??
              errorMessage;
        } else if (responseData is String && responseData.isNotEmpty) {
          errorMessage = responseData;
        }

        if (statusCode == 409) {
          throw ConflictException(errorMessage);
        } else if (statusCode == 422) {
          throw ValidationException(errorMessage);
        } else if (statusCode != null && statusCode >= 500) {
          throw ServerException(errorMessage, statusCode);
        } else {
          throw ServerException(errorMessage, statusCode);
        }

      case DioExceptionType.cancel:
        throw const ServerException('Request was cancelled.');

      case DioExceptionType.unknown:
      default:
        if (err.error is ServerException ||
            err.error is NetworkException ||
            err.error is ConflictException ||
            err.error is ValidationException) {
          return handler.next(err);
        }
        throw ServerException(err.message ?? 'An unknown error occurred.');
    }
  }
}
