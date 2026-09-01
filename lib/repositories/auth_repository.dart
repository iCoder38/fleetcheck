import 'package:dio/dio.dart';
import '../core/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../core/services/storage_service.dart';
import '../core/services/session_manager.dart';
import '../models/driver_model.dart';

class AuthRepository {
  final ApiService _api;
  final StorageService _storage;

  AuthRepository({ApiService? api, StorageService? storage})
      : _api     = api     ?? ApiService(),
        _storage  = storage ?? StorageService();

  Future<ApiResult<DriverModel>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      // Make a single raw request so we can extract both the driver AND
      // the token from the same response, then await the token write
      // before returning — preventing the race condition where the app
      // navigated to the next screen before the token was persisted.
      final response = await _api.post(ApiConstants.login, data: {
        'identifier': identifier,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final envelope = response.data as Map<String, dynamic>;
        if (envelope['success'] == true) {
          // API envelope: { "success": true, "data": { "driver": {...}, "token": "..." } }
          // Must read from the inner 'data' key, not from envelope root.
          final inner  = envelope['data'] as Map<String, dynamic>;
          final driver = DriverModel.fromJson(inner['driver'] as Map<String, dynamic>);
          final token  = inner['token'] as String;

          // AWAIT every storage write before returning — all three are
          // async operations; not awaiting them was the root cause of
          // the 401 "Missing Authorization header" error on QR scan.
          await _storage.saveToken(token);
          await _storage.saveDriverData(driver.toJson());
          await _storage.setLoggedIn(true);
          // Saved so an expired token can be silently renewed later
          // without interrupting the driver mid-inspection — see
          // SessionManager / ApiService's 401 handling.
          await _storage.saveCredentials(identifier, password);
          // Allow a later 401 to trigger the forced-logout flow again —
          // it was disabled after being handled once.
          SessionManager.reset();

          return ApiResult.success(driver);
        }
        return ApiResult.error(envelope['message'] as String? ?? 'Login failed');
      }
      return ApiResult.error('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      // The backend returns 401 (not just for auth-token issues but) for
      // wrong-credential login attempts too, with the real reason in the
      // JSON body's 'message' field — surface that instead of the raw
      // DioException text (e.g. "Invalid Password" instead of a dump of
      // the HTTP status explanation).
      final responseData = e.response?.data;
      final msg = (responseData is Map ? responseData['message'] : null) ??
          e.message ??
          'Login failed';
      return ApiResult.error(msg.toString());
    } on Exception catch (e) {
      return ApiResult.error('Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout);
    } catch (_) {}
    await _storage.clearAll();
  }

  Future<ApiResult<bool>> forgotPassword(String identifier) async {
    return _api.call<bool>(
      request: () => _api
          .post(ApiConstants.forgotPassword, data: {'identifier': identifier}),
      fromJson: (_) => true,
    );
  }

  Future<ApiResult<String>> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    return _api.call<String>(
      request: () => _api.post(ApiConstants.verifyOtp, data: {
        'identifier': identifier,
        'otp': otp,
      }),
      fromJson: (data) => data['reset_token'] as String,
    );
  }

  Future<ApiResult<bool>> resendOtp(String identifier) async {
    return _api.call<bool>(
      request: () =>
          _api.post(ApiConstants.resendOtp, data: {'identifier': identifier}),
      fromJson: (_) => true,
    );
  }

  Future<ApiResult<bool>> resetPassword({
    required String resetToken,
    required String password,
    required String confirmPassword,
  }) async {
    return _api.call<bool>(
      request: () => _api.post(ApiConstants.resetPassword, data: {
        'reset_token': resetToken,
        'password': password,
        'confirm_password': confirmPassword,
      }),
      fromJson: (_) => true,
    );
  }

  Future<ApiResult<bool>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final result = await _api.call<bool>(
      request: () => _api.post(ApiConstants.changePassword, data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
      fromJson: (_) => true,
    );
    if (result.success) {
      // Keep the saved credentials in sync with the new password so a
      // later silent relogin (on token expiry) doesn't fail with the
      // now-stale old password.
      final creds = await _storage.getCredentials();
      if (creds != null) {
        await _storage.saveCredentials(creds.identifier, newPassword);
      }
    }
    return result;
  }

  DriverModel? getCachedDriver() {
    final data = _storage.getDriverData();
    return data != null ? DriverModel.fromJson(data) : null;
  }

  bool get isLoggedIn => _storage.isLoggedIn;
  bool get isFirstLaunch => _storage.isFirstLaunch;
}
