import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: Duration(seconds: AppConstants.apiTimeoutSeconds),
      receiveTimeout: Duration(seconds: AppConstants.apiTimeoutSeconds),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    // Auth Interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.keyAuthToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: AppConstants.keyAuthToken);
        }
        return handler.next(error);
      },
    ));

    // Logging in debug
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return await _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  Future<Response> postFormData(String path, FormData formData) async {
    return await _dio.post(path, data: formData);
  }

  /// Generic API call with error handling
  Future<ApiResult<T>> call<T>({
    required Future<Response> Function() request,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await request();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return ApiResult.success(fromJson(data));
        }
        return ApiResult.error(data['message'] ?? 'Unknown error');
      }
      return ApiResult.error('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return ApiResult.error('Connection timed out. Please check your internet.');
      }
      if (e.type == DioExceptionType.connectionError) {
        return ApiResult.error('No internet connection.');
      }
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      return ApiResult.error(msg.toString());
    } catch (e) {
      return ApiResult.error('Unexpected error: $e');
    }
  }
}

class ApiResult<T> {
  final T? data;
  final String? error;
  final bool success;

  const ApiResult._({this.data, this.error, required this.success});

  factory ApiResult.success(T data) =>
      ApiResult._(data: data, success: true);

  factory ApiResult.error(String message) =>
      ApiResult._(error: message, success: false);
}
