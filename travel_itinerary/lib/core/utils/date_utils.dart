import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  static String formatTime(DateTime d) => DateFormat('hh:mm a').format(d);
  static String formatDateTime(DateTime d) => DateFormat('dd MMM yyyy, hh:mm a').format(d);
  static String formatShort(DateTime d) => DateFormat('dd MMM').format(d);
  static String formatMonthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
  static String formatDayName(DateTime d) => DateFormat('EEEE').format(d);
  static String formatDayShort(DateTime d) => DateFormat('EEE, dd MMM').format(d);
  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static int tripDuration(String start, String end) {
    final s = DateTime.parse(start);
    final e = DateTime.parse(end);
    return e.difference(s).inDays + 1;
  }

  static String dateRange(String start, String end) {
    return '${formatShort(DateTime.parse(start))} – ${formatDate(DateTime.parse(end))}';
  }
}
