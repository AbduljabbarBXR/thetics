const _monthsShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _monthsLong = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _weekdaysShort = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const _weekdaysLong = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Stable local date key, e.g. `2026-10-21`.
String dateKey(DateTime date) {
  final local = date.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}-$m-$d';
}

DateTime dateFromKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

DateTime dayStart(DateTime date) => DateTime(date.year, date.month, date.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String monthShort(DateTime date) => _monthsShort[date.month - 1];

String monthLong(DateTime date) => _monthsLong[date.month - 1];

String weekdayShort(DateTime date) => _weekdaysShort[date.weekday - 1];

String weekdayLong(DateTime date) => _weekdaysLong[date.weekday - 1];

String formatShortDate(DateTime date) => '${monthShort(date)} ${date.day}';

String formatLongDate(DateTime date) =>
    '${weekdayLong(date)}, ${monthLong(date)} ${date.day}';

String formatDate(DateTime date) =>
    '${monthShort(date)} ${date.day}, ${date.year}';

String relativeDay(DateTime date, {DateTime? now}) {
  final today = dayStart(now ?? DateTime.now());
  final target = dayStart(date);
  final diff = today.difference(target).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff == -1) return 'Tomorrow';
  if (diff > 1 && diff < 7) return weekdayLong(date);
  return formatShortDate(date);
}

DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

DateTime startOfWeek(DateTime date) {
  final start = dayStart(date);
  return addDays(start, -(start.weekday - 1));
}

List<DateTime> lastNDays(int n, {DateTime? end}) {
  final anchor = dayStart(end ?? DateTime.now());
  return List<DateTime>.generate(n, (i) => addDays(anchor, -(n - 1 - i)));
}

/// Weeks are Monday-based. Returns a 0..n streak where the current week
/// counts only if there is activity in it.
int weekStreak(Iterable<DateTime> activity, {DateTime? now}) {
  final activeWeeks = activity.map((d) => dateKey(startOfWeek(d))).toSet();
  if (activeWeeks.isEmpty) return 0;
  var cursor = startOfWeek(now ?? DateTime.now());
  if (!activeWeeks.contains(dateKey(cursor))) {
    cursor = addDays(cursor, -7);
  }
  var streak = 0;
  while (activeWeeks.contains(dateKey(cursor))) {
    streak++;
    cursor = addDays(cursor, -7);
  }
  return streak;
}

String greeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 5) return 'Late session';
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
