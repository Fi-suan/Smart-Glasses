import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';

class ApiClient {
  static Dio? _dio;
  static final Logger _logger = Logger();

  static Dio get dio {
    if (_dio == null) {
      _dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

      // Add logging interceptor
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            _logger.d('REQUEST[${options.method}] => ${options.uri}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            _logger.d(
              'RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
            );
            return handler.next(response);
          },
          onError: (error, handler) {
            _logger.e(
              'ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}',
            );
            return handler.next(error);
          },
        ),
      );
    }
    return _dio!;
  }

  // Reset dio instance (useful for testing or changing config)
  static void reset() {
    _dio = null;
  }
}
