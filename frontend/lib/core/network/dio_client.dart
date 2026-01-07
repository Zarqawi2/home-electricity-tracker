import 'package:dio/dio.dart';
import '../config/app_config.dart';

class DioClient {
  DioClient(this._config) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: Duration(milliseconds: _config.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: _config.receiveTimeoutMs),
        headers: {'Accept': 'application/json'},
      ),
    );

    // if (kDebugMode) {
    //   _dio.interceptors.add(
    //     LogInterceptor(
    //       responseBody: true,
    //       requestBody: true,
    //       requestHeader: true,
    //     ),
    //   );
    // }
  }

  final AppConfig _config;
  late final Dio _dio;

  Dio get dio => _dio;

  String mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'کات زیاد بوو، تکایە دووبارە هەوڵ بدە.';
    }

    if (error.type == DioExceptionType.badResponse) {
      final status = error.response?.statusCode;
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response?.data['message'] as String?)
          : null;
      return message ?? 'هەڵەی ڕاژه‌کار (${status ?? ''}).';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'ناتوانرێت پەیوەندی بکرێت بە سێرڤەرەکە. تکایە پەیوەندیت بپشکنە.';
    }

    return 'هەڵەی چاوەڕوان نەکراو. تکایە دووبارە هەوڵ بدە.';
  }
}
