import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  AppInfoService._();

  static PackageInfo? _cached;

  static Future<PackageInfo> _packageInfo() async {
    return _cached ??= await PackageInfo.fromPlatform();
  }

  /// e.g. "1.0.0"
  static Future<String> getAppVersion() async {
    final info = await _packageInfo();
    return info.version;
  }

  /// e.g. "1.0.0+3"
  static Future<String> getAppVersionWithBuildNumber() async {
    final info = await _packageInfo();
    return '${info.version}+${info.buildNumber}';
  }
}
