import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;
  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Auth Token (secure) ───────────────────────────────
  Future<void> saveToken(String token) =>
      _secure.write(key: AppConstants.keyAuthToken, value: token);

  Future<String?> getToken() =>
      _secure.read(key: AppConstants.keyAuthToken);

  Future<void> deleteToken() =>
      _secure.delete(key: AppConstants.keyAuthToken);

  // ─── Saved credentials (secure) ────────────────────────
  // Used to silently re-authenticate via /auth/login when the access
  // token expires, so a session timeout doesn't interrupt an in-progress
  // inspection. Cleared on explicit logout or when a silent relogin
  // attempt itself fails (see SessionManager.handleSessionExpired).
  Future<void> saveCredentials(String identifier, String password) async {
    await _secure.write(key: AppConstants.keyAuthIdentifier, value: identifier);
    await _secure.write(key: AppConstants.keyAuthPassword, value: password);
  }

  Future<StoredCredentials?> getCredentials() async {
    final identifier = await _secure.read(key: AppConstants.keyAuthIdentifier);
    final password = await _secure.read(key: AppConstants.keyAuthPassword);
    if (identifier == null || password == null) return null;
    return StoredCredentials(identifier: identifier, password: password);
  }

  Future<void> deleteCredentials() async {
    await _secure.delete(key: AppConstants.keyAuthIdentifier);
    await _secure.delete(key: AppConstants.keyAuthPassword);
  }

  // ─── Driver Data (shared prefs) ───────────────────────
  Future<void> saveDriverData(Map<String, dynamic> data) async {
    await _prefs.setString(AppConstants.keyDriverData, jsonEncode(data));
  }

  Map<String, dynamic>? getDriverData() {
    final s = _prefs.getString(AppConstants.keyDriverData);
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  Future<void> deleteDriverData() =>
      _prefs.remove(AppConstants.keyDriverData);

  // ─── Login state ─────────────────────────────────────
  Future<void> setLoggedIn(bool val) =>
      _prefs.setBool(AppConstants.keyIsLoggedIn, val);

  bool get isLoggedIn => _prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;

  // ─── First launch ────────────────────────────────────
  Future<void> setFirstLaunchDone() =>
      _prefs.setBool(AppConstants.keyIsFirstLaunch, false);

  bool get isFirstLaunch =>
      _prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;

  // ─── Clear all ───────────────────────────────────────
  Future<void> clearAll() async {
    await _secure.deleteAll();
    await _prefs.clear();
  }
}

class StoredCredentials {
  final String identifier;
  final String password;
  const StoredCredentials({required this.identifier, required this.password});
}
