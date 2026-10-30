/// Calendar days as `yyyy-MM-dd` strings, the format the streak service
/// already stores.
String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? parseDayKey(String s) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (m == null) return null;
  final y = int.parse(m.group(1)!),
      mo = int.parse(m.group(2)!),
      d = int.parse(m.group(3)!);
  final dt = DateTime(y, mo, d);
  // Reject 2026-02-31 style dates, which DateTime silently rolls over.
  return dt.year == y && dt.month == mo && dt.day == d ? dt : null;
}

/// Whole days since 2020-01-01. Used to pick the same "of the day" item for
/// everyone on the same date, independent of time zone or time of day.
int dayNumber(DateTime d) => DateTime.utc(d.year, d.month, d.day)
    .difference(DateTime.utc(2020, 1, 1))
    .inDays;

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
