import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _fullDateFormat = DateFormat('EEEE, MMMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _compactDateFormat = DateFormat('yyyy-MM-dd');

  /// Formats date for timeline header ("October 2024")
  static String formatMonthYear(DateTime? date) {
    if (date == null) return 'Unknown Date';
    return _monthYearFormat.format(date);
  }

  /// Formats date cleanly ("Friday, Oct 12, 2024")
  static String formatFull(DateTime? date, {bool isApproximate = false}) {
    if (date == null) return 'Unknown Date';
    final formatted = _fullDateFormat.format(date);
    return isApproximate ? 'Around $formatted' : formatted;
  }

  /// Formats short date ("Oct 12, 2024")
  static String formatShort(DateTime? date, {bool isApproximate = false}) {
    if (date == null) return 'Unknown';
    final formatted = _shortDateFormat.format(date);
    return isApproximate ? '~$formatted' : formatted;
  }

  /// Compact ISO date "YYYY-MM-DD"
  static String formatCompact(DateTime? date) {
    if (date == null) return '';
    return _compactDateFormat.format(date);
  }

  /// Parses date string safely without timezone offset shifting
  static DateTime? parseCompact(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    try {
      final parts = input.trim().split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
      return DateTime.parse(input);
    } catch (_) {
      return null;
    }
  }
}
