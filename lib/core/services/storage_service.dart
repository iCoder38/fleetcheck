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
      Future(() => _prefs.remove(AppConstants.keyDriverData));

  // ─── Login state ─────────────────────────────────────
  Future<void> setLoggedIn(bool val) =>
      Future(() => _prefs.setBool(AppConstants.keyIsLoggedIn, val));

  bool get isLoggedIn => _prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;

  // ─── First launch ────────────────────────────────────
  Future<void> setFirstLaunchDone() =>
      Future(() => _prefs.setBool(AppConstants.keyIsFirstLaunch, false));

  bool get isFirstLaunch =>
      _prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;

  // ─── Clear all ───────────────────────────────────────
  Future<void> clearAll() async {
    await _secure.deleteAll();
    await _prefs.clear();
  }
}
