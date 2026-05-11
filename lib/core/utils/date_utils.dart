import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date, {String locale = 'ar'}) {
    return DateFormat('EEEE d MMMM yyyy', locale).format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isInRange(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static DateTime clampDay(int year, int month, int day) {
    final maxDay = daysInMonth(year, month);
    return DateTime(year, month, day.clamp(1, maxDay));
  }
}