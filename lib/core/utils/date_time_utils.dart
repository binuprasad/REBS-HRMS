import 'package:intl/intl.dart';

class DateTimeUtils {
  static final DateFormat _dateOnlyFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy • hh:mm a');
  static final DateFormat _monthYearFormat = DateFormat('yyyy-MM');
  static final DateFormat _displayDateFormat = DateFormat('EEE, MMM dd, yyyy');

  static String toDateString(DateTime dateTime) => _dateOnlyFormat.format(dateTime);

  static String toMonthString(DateTime dateTime) => _monthYearFormat.format(dateTime);

  static String toDisplayDate(DateTime dateTime) => _displayDateFormat.format(dateTime);

  static String toDisplayTime(DateTime dateTime) => _timeFormat.format(dateTime);

  static String toDisplayDateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  static String formatDurationMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  static DateTime parseDate(String dateStr) {
    return _dateOnlyFormat.parse(dateStr);
  }

  static int calculateInclusiveDays(DateTime start, DateTime end) {
    final cleanStart = DateTime(start.year, start.month, start.day);
    final cleanEnd = DateTime(end.year, end.month, end.day);
    return cleanEnd.difference(cleanStart).inDays + 1;
  }
}
