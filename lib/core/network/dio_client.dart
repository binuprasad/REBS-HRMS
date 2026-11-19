import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../storage/hive_service.dart';
import 'error_interceptor.dart';
import 'logging_interceptor.dart';

class DioClient {
  late final Dio _dio;
  String _baseUrl;
  final HiveService? hiveService;

  DioClient({String? baseUrl, Dio? customDio, this.hiveService})
      : _baseUrl = baseUrl ??
            (hiveService?.settingsBox.get('api_base_url') as String?) ??
            ApiEndpoints.defaultBaseUrl {
    _dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
            receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
            sendTimeout: const Duration(milliseconds: AppConstants.sendTimeoutMs),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.addAll([
      AppLoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;
  String get baseUrl => _baseUrl;

  Future<void> updateBaseUrl(String newBaseUrl) async {
    _baseUrl = newBaseUrl;
    _dio.options.baseUrl = newBaseUrl;
    if (hiveService != null) {
      await hiveService!.settingsBox.put('api_base_url', newBaseUrl);
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
