import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/api_constants.dart';

/// FleetCheck API Logger
///
/// Writes every API request and response to a persistent log file on the device.
/// Designed for testing — helps diagnose issues without needing a debugger attached.
///
/// Log file location:
///   Android: /data/data/<package>/files/fleetcheck_api.log
///   iOS:     <app_documents>/fleetcheck_api.log
///
/// Usage:
///   await LoggerService().init();           // call once in main()
///   LoggerService().logRequest(...)         // called automatically by ApiService
///   LoggerService().logResponse(...)        // called automatically by ApiService
///   LoggerService().logError(...)           // called automatically by ApiService
///
/// File management:
///   - Max size: 2 MB. When exceeded the file is renamed to fleetcheck_api.log.bak
///     and a fresh log starts. At most one .bak is kept.
///   - Each app session writes a SESSION START banner so you can separate runs.
///   - Call LoggerService().clearLog() to wipe the log manually (e.g. from a
///     debug settings screen).
///   - Call LoggerService().logFilePath to get the path to show the user.

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  static const int _maxBytes     = 2 * 1024 * 1024; // 2 MB
  static const String _fileName  = 'fleetcheck_api.log';
  static const String _bakName   = 'fleetcheck_api.log.bak';

  File?   _logFile;
  File?   _bakFile;
  bool    _ready = false;

  // ── Initialise ────────────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/$_fileName');
      _bakFile = File('${dir.path}/$_bakName');
      _ready   = true;

      await _rotate();
      await _write(_sessionBanner());
    } catch (e) {
      debugPrint('[LoggerService] init failed: $e');
    }
  }

  String get logFilePath => _logFile?.path ?? 'not initialised';

  // ── Public API (called by ApiService interceptors) ────────────────────────

  Future<void> logRequest({
    required String method,
    required String url,
    required Map<String, dynamic> headers,
    dynamic body,
  }) async {
    final masked = _maskHeaders(headers);
    final bodyStr = _prettyJson(body);
    final block = '''
┌─────────────────────────────────────────────────────────────
│ ▶ REQUEST   ${_ts()}
│ $method $url
│ Headers:
${_indent(masked)}
│ Body:
${_indent(bodyStr)}
└─────────────────────────────────────────────────────────────
''';
    await _write(block);
    debugPrint(block);
  }

  Future<void> logResponse({
    required int statusCode,
    required String url,
    required int durationMs,
    dynamic body,
    Map<String, dynamic>? headers,
  }) async {
    final icon    = statusCode >= 200 && statusCode < 300 ? '✅' : '⚠️ ';
    final bodyStr = _prettyJson(body);
    final block = '''
┌─────────────────────────────────────────────────────────────
│ $icon RESPONSE  ${_ts()}
│ $statusCode  $url  (${durationMs}ms)
│ Body:
${_indent(bodyStr)}
└─────────────────────────────────────────────────────────────
''';
    await _write(block);
    debugPrint(block);
  }

  Future<void> logError({
    required String method,
    required String url,
    required String error,
    int? statusCode,
    dynamic responseBody,
  }) async {
    final bodyStr = _prettyJson(responseBody);
    final block = '''
┌─────────────────────────────────────────────────────────────
│ ❌ ERROR     ${_ts()}
│ $method $url${statusCode != null ? '  [HTTP $statusCode]' : ''}
│ Error: $error
${responseBody != null ? '│ Response Body:\n${_indent(bodyStr)}' : ''}
└─────────────────────────────────────────────────────────────
''';
    await _write(block);
    debugPrint(block);
  }

  /// Writes a plain info line (e.g. "App launched", "User logged out")
  Future<void> logInfo(String message) async {
    final line = '│ ℹ️  INFO    ${_ts()}\n│ $message\n';
    await _write(line);
    debugPrint(line);
  }

  /// Deletes the log file. Useful from a debug settings screen.
  Future<void> clearLog() async {
    try {
      if (await _logFile?.exists() == true) await _logFile!.delete();
      if (await _bakFile?.exists() == true) await _bakFile!.delete();
      await _write(_sessionBanner());
    } catch (_) {}
  }

  /// Returns the last [lines] lines of the log for in-app display.
  Future<String> tailLog([int lines = 200]) async {
    try {
      if (_logFile == null || !await _logFile!.exists()) return '(log empty)';
      final all = await _logFile!.readAsLines();
      final tail = all.length > lines ? all.sublist(all.length - lines) : all;
      return tail.join('\n');
    } catch (e) {
      return 'Could not read log: $e';
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  String _pad(int n, [int w = 2]) => n.toString().padLeft(w, '0');

  String _ts() {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)} '
        '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}.${_pad(now.millisecond, 3)}';
  }

  String _sessionBanner() => '''
╔═════════════════════════════════════════════════════════════╗
║  FleetCheck API Log — Session started ${_ts()}
║  Base URL: ${ApiConstants.baseUrl}
╚═════════════════════════════════════════════════════════════╝

''';

  /// Masks the Authorization header value so tokens are not exposed in logs
  /// shared with others. Shows first 8 chars + *** for security.
  String _maskHeaders(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) {
      final val = copy['Authorization'].toString();
      if (val.length > 15) {
        copy['Authorization'] = '${val.substring(0, 15)}***';
      }
    }
    return _prettyJson(copy);
  }

  String _prettyJson(dynamic obj) {
    if (obj == null) return '  (none)';
    try {
      if (obj is String) {
        // Try to parse and re-pretty if it looks like JSON
        final decoded = jsonDecode(obj);
        return const JsonEncoder.withIndent('  ').convert(decoded)
            .split('\n').map((l) => '  $l').join('\n');
      }
      return const JsonEncoder.withIndent('  ').convert(obj)
          .split('\n').map((l) => '  $l').join('\n');
    } catch (_) {
      return '  ${obj.toString().replaceAll('\n', '\n  ')}';
    }
  }

  String _indent(String text) => text.split('\n').map((l) => '│ $l').join('\n');

  Future<void> _write(String text) async {
    if (!_ready || _logFile == null) return;
    try {
      await _rotate();
      await _logFile!.writeAsString(text, mode: FileMode.append, flush: true);
    } catch (e) {
      debugPrint('[LoggerService] write error: $e');
    }
  }

  Future<void> _rotate() async {
    if (_logFile == null) return;
    try {
      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > _maxBytes) {
          // Rename current log to .bak (overwrites previous .bak)
          await _logFile!.rename(_bakFile!.path);
          debugPrint('[LoggerService] Log rotated → $_bakName');
        }
      }
    } catch (_) {}
  }
}
