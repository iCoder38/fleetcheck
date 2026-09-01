import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  /// Format date as MM/DD/YYYY
  static String formatDate(DateTime date) =>
      DateFormat('MM/dd/yyyy').format(date);

  /// Format time as hh:mm AM/PM
  static String formatTime(DateTime time) =>
      DateFormat('hh:mm a').format(time);

  /// Format date + time combined
  static String formatDateTime(DateTime dt) =>
      '${formatDate(dt)} ${formatTime(dt)}';

  /// Current date as MM/DD/YYYY
  static String get currentDate => formatDate(DateTime.now());

  /// Current time
  static String get currentTime => formatTime(DateTime.now());

  /// Current full datetime
  static String get currentDateTime => formatDateTime(DateTime.now());

  /// Parse ISO date to DateTime
  static DateTime? parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try { return DateTime.parse(s); } catch (_) { return null; }
  }

  /// Truncate string for display
  static String truncate(String s, {int max = 40}) =>
      s.length > max ? '${s.substring(0, max)}…' : s;

  /// Generate a local inspection ID for display before server assigns one
  static String tempInspectionId() =>
      'FC-${DateTime.now().millisecondsSinceEpoch}';
}
