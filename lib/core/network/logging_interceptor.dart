import 'dart:developer' as developer;
import 'package:dio/dio.dart';

class AppLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '--> ${options.method} ${options.uri}',
      name: 'Dio.Request',
    );
    if (options.data != null) {
      developer.log('Body: ${options.data}', name: 'Dio.Request');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      '<-- ${response.statusCode} ${response.requestOptions.uri}',
      name: 'Dio.Response',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '<-- ERROR [${err.response?.statusCode}] ${err.requestOptions.uri}: ${err.message}',
      name: 'Dio.Error',
      error: err.error,
    );
    super.onError(err, handler);
  }
}
