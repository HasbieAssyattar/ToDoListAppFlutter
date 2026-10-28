import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShort(DateTime? date) {
    if (date == null) return '';
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDate = DateTime(date.year, date.month, date.day);

      if (targetDate == today) {
        return 'Hari ini, ${DateFormat('HH:mm').format(date)}';
      } else if (targetDate == today.add(const Duration(days: 1))) {
        return 'Besok, ${DateFormat('HH:mm').format(date)}';
      } else if (targetDate == today.subtract(const Duration(days: 1))) {
        return 'Kemarin, ${DateFormat('HH:mm').format(date)}';
      }

      return DateFormat('d MMM, HH:mm').format(date);
    } catch (_) {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  static String formatFull(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('EEEE, d MMMM yyyy HH:mm').format(date);
  }

  static bool isOverdue(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }
}
