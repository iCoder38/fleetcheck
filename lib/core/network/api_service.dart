import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';
import '../services/logger_service.dart';
import '../services/session_manager.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  // Routed through the shared StorageService singleton — NOT a separate
  // FlutterSecureStorage instance. On Android, StorageService uses
  // encryptedSharedPreferences while a plain FlutterSecureStorage() uses the
  // EncryptedFile backend, a different store. A token written by
  // StorageService would be invisible to a raw FlutterSecureStorage read,
  // causing every authenticated request to silently omit the Authorization
  // header and get a 401 back from the server.
  final StorageService _storage = StorageService();
  final LoggerService _logger = LoggerService();

  // Single-flight guard: if several requests 401 at once (e.g. a screen
  // fires 3 parallel calls right as the token expires), they all share
  // one relogin attempt instead of each firing its own /auth/login call.
  Future<String?>? _silentReloginFuture;

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
        final token = await _storage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final path = error.requestOptions.path;
        final alreadyRetried = error.requestOptions.extra['_retriedAfterRelogin'] == true;

        if (error.response?.statusCode == 401 &&
            !SessionManager.isPublicPath(path) &&
            !alreadyRetried) {
          final newToken = await _silentRelogin();
          if (newToken != null) {
            await _logger.logInfo('Session silently renewed — retrying $path');
            try {
              final retryOptions = error.requestOptions
                ..headers['Authorization'] = 'Bearer $newToken'
                ..extra['_retriedAfterRelogin'] = true;
              final response = await _dio.fetch(retryOptions);
              return handler.resolve(response);
            } catch (_) {
              // Retry itself failed — fall through to the hard logout below.
            }
          }
          await _logger.logInfo('Session expired — redirecting to login ($path)');
          await SessionManager.handleSessionExpired();
        }
        return handler.next(error);
      },
    ));

    // Logger Interceptor — writes every request/response/error to a
    // persistent log file (see LoggerService) for on-device debugging.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.extra['_requestStart'] = DateTime.now().millisecondsSinceEpoch;
        await _logger.logRequest(
          method: options.method,
          url: '${options.baseUrl}${options.path}',
          headers: Map<String, dynamic>.from(options.headers),
          body: options.data,
        );
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        final start =
            response.requestOptions.extra['_requestStart'] as int? ?? 0;
        final duration = DateTime.now().millisecondsSinceEpoch - start;
        await _logger.logResponse(
          statusCode: response.statusCode ?? 0,
          url: '${response.requestOptions.baseUrl}${response.requestOptions.path}',
          durationMs: duration,
          body: response.data,
          headers: response.headers.map,
        );
        return handler.next(response);
      },
      onError: (error, handler) async {
        final start = error.requestOptions.extra['_requestStart'] as int? ?? 0;
        final duration = DateTime.now().millisecondsSinceEpoch - start;
        await _logger.logError(
          method: error.requestOptions.method,
          url: '${error.requestOptions.baseUrl}${error.requestOptions.path}',
          error: '${error.type.name}: ${error.message}  (${duration}ms)',
          statusCode: error.response?.statusCode,

          responseBody: error.response?.data,
        );
        return handler.next(error);
      },
    ));
  }

  /// Silently re-authenticates using the credentials saved at login, so an
  /// expired access token doesn't interrupt the driver mid-task. Returns
  /// the new token, or null if there are no saved credentials or the
  /// relogin attempt itself fails (e.g. the password was changed
  /// elsewhere / the account was disabled).
  Future<String?> _silentRelogin() {
    return _silentReloginFuture ??=
        _doSilentRelogin().whenComplete(() => _silentReloginFuture = null);
  }

  Future<String?> _doSilentRelogin() async {
    final creds = await _storage.getCredentials();
    if (creds == null) return null;

    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'identifier': creds.identifier,
        'password': creds.password,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final envelope = response.data as Map<String, dynamic>;
        if (envelope['success'] == true) {
          final inner = envelope['data'] as Map<String, dynamic>;
          final newToken = inner['token'] as String;
          await _storage.saveToken(newToken);
          return newToken;
        }
      }
    } catch (_) {
      // Swallow — the caller treats a null return as "relogin failed" and
      // falls back to the hard logout flow.
    }
    return null;
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
        final envelope = response.data as Map<String, dynamic>;
        if (envelope['success'] == true) {
          // The API wraps every success payload as:
          //   { "success": true, "message": "...", "data": { ... } }
          // Pass the inner 'data' map to fromJson so repository callbacks
          // can read keys like data['stats'], data['qr_data'], data['driver']
          // directly without knowing about the outer envelope.
          final inner = envelope['data'] as Map<String, dynamic>? ?? {};
          return ApiResult.success(fromJson(inner));
        }
        return ApiResult.error(envelope['message'] ?? 'Unknown error');
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
      final responseData = e.response?.data;
      final msg = (responseData is Map ? responseData['message'] : null) ??
          e.message ??
          'Network error';
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
