import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Don't add Authorization header for authentication endpoints
          final isAuthEndpoint =
              options.path.contains('auth/login/') ||
              options.path.contains('auth/register/') ||
              options.path.contains('auth/token/refresh/');

          if (!isAuthEndpoint) {
            // Add token to requests (only for authenticated endpoints)
            String? token = await _storage.read(key: 'access_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          print('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          print('ERROR[${e.response?.statusCode}] => MESSAGE: ${e.message}');

          // Don't try to refresh token for authentication endpoints or if no refresh token exists
          final isAuthEndpoint =
              e.requestOptions.path.contains('auth/login/') ||
              e.requestOptions.path.contains('auth/register/') ||
              e.requestOptions.path.contains('auth/token/refresh/');

          // Handle 401 Unauthorized - try to refresh token (only for authenticated endpoints)
          if (e.response?.statusCode == 401 && !isAuthEndpoint) {
            try {
              String? refreshToken = await _storage.read(key: 'refresh_token');

              // Only try to refresh if we have a refresh token
              if (refreshToken != null && refreshToken.isNotEmpty) {
                // Try to refresh the token (don't add Authorization header for refresh endpoint)
                final response = await dio.post(
                  ApiConstants.tokenRefresh,
                  data: {'refresh': refreshToken},
                  options: Options(
                    headers: {
                      'Content-Type': 'application/json',
                      'Accept': 'application/json',
                    },
                  ),
                );

                if (response.statusCode == 200) {
                  String newAccessToken = response.data['access'];
                  await _storage.write(
                    key: 'access_token',
                    value: newAccessToken,
                  );

                  // Retry the original request
                  e.requestOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';
                  return handler.resolve(await dio.fetch(e.requestOptions));
                }
              }
            } catch (refreshError) {
              // Refresh failed, clear tokens
              await _storage.deleteAll();
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  // Token management
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  // HTTP Methods
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await dio.delete(path);
  }
}
