import '../core/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../core/services/storage_service.dart';
import '../models/driver_model.dart';

class AuthRepository {
  final ApiService _api;
  final StorageService _storage;

  AuthRepository({ApiService? api, StorageService? storage})
      : _api = api ?? ApiService(),
        _storage = storage ?? StorageService();

  Future<ApiResult<DriverModel>> login({
    required String identifier,
    required String password,
  }) async {
    return _api.call<DriverModel>(
      request: () => _api.post(
        ApiConstants.login,
        data: {
          'identifier': identifier,
          'password': password,
        },
      ),
      fromJson: (data) {
        final responseData = data['data'] as Map<String, dynamic>;

        final driver = DriverModel.fromJson(
          responseData['driver'] as Map<String, dynamic>,
        );

        _storage.saveToken(responseData['token'] as String);
        _storage.saveDriverData(driver.toJson());
        _storage.setLoggedIn(true);

        return driver;
      },
    );
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
    return _api.call<bool>(
      request: () => _api.post(ApiConstants.changePassword, data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
      fromJson: (_) => true,
    );
  }

  DriverModel? getCachedDriver() {
    final data = _storage.getDriverData();
    return data != null ? DriverModel.fromJson(data) : null;
  }

  bool get isLoggedIn => _storage.isLoggedIn;
  bool get isFirstLaunch => _storage.isFirstLaunch;
}
