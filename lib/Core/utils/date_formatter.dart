import 'package:intl/intl.dart';

class DateFormatter {
  // Format: Jan 15, 2026
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Format: 15/01/2026
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format: January 15, 2026
  static String formatDateLong(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  // Format: 15 Jan
  static String formatDateCompact(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  // Format: Monday, Jan 15
  static String formatDateWithDay(DateTime date) {
    return DateFormat('EEEE, MMM dd').format(date);
  }

  // Format: 2:30 PM
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  // Format: Jan 15, 2026 at 2:30 PM
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(date);
  }

  // Format: January 2026
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  // Format: Jan 2026
  static String formatMonthYearShort(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  // Relative time (e.g., "Today", "Yesterday", "2 days ago")
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is in this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // Check if date is in this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  // Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    return startOfWeek(
      date,
    ).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  // Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  // Parse string to DateTime
  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
}
