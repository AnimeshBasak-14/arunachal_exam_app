/// One block of the exam timer, e.g. `02` over `MONTHS`.
class CountdownSegment {
  final String value;
  final String label;
  const CountdownSegment(this.value, this.label);
}

enum CountdownState { running, examDay, passed }

class Countdown {
  final CountdownState state;
  final List<CountdownSegment> segments;

  /// True while seconds are shown, so the card must refresh every second.
  final bool ticksEverySecond;
  const Countdown(this.state, this.segments, {this.ticksEverySecond = false});
}

DateTime _addMonths(DateTime d, int months) {
  final total = d.year * 12 + (d.month - 1) + months;
  final y = total ~/ 12, m = total % 12 + 1;
  final lastDay = DateTime(y, m + 1, 0).day;
  return DateTime(
      y, m, d.day > lastDay ? lastDay : d.day, d.hour, d.minute, d.second);
}

String _two(int n) => n.toString().padLeft(2, '0');

/// Time left until the start of [examDate] (00:00 local), in the format that
/// suits how close it is:
///
/// * 1 month or more        → MONTHS : DAYS
/// * under a month, 7+ days → DAYS : HOURS
/// * under 7 days           → DAYS : HOURS : MINUTES
/// * under 3 days           → DAYS : HOURS : MINUTES : SECONDS
///
/// The exam time of day isn't known, so the countdown runs to midnight at the
/// start of the exam date.
Countdown examCountdown(DateTime now, DateTime examDate) {
  final target = DateTime(examDate.year, examDate.month, examDate.day);
  final today = DateTime(now.year, now.month, now.day);
  if (target.isBefore(today)) return const Countdown(CountdownState.passed, []);
  if (!target.isAfter(now)) return const Countdown(CountdownState.examDay, []);

  var months = (target.year - now.year) * 12 + target.month - now.month;
  while (months > 0 && _addMonths(now, months).isAfter(target)) {
    months--;
  }
  final rest = target.difference(_addMonths(now, months));
  final days = rest.inDays;
  final hours = rest.inHours % 24;
  final minutes = rest.inMinutes % 60;
  final seconds = rest.inSeconds % 60;
  final left = target.difference(now);

  if (months >= 1) {
    return Countdown(CountdownState.running, [
      CountdownSegment(_two(months), months == 1 ? 'MONTH' : 'MONTHS'),
      CountdownSegment(_two(days), days == 1 ? 'DAY' : 'DAYS'),
    ]);
  }
  final d = CountdownSegment(_two(days), days == 1 ? 'DAY' : 'DAYS');
  final h = CountdownSegment(_two(hours), 'HRS');
  final m = CountdownSegment(_two(minutes), 'MIN');
  final s = CountdownSegment(_two(seconds), 'SEC');

  if (left < const Duration(days: 3)) {
    return Countdown(CountdownState.running, [d, h, m, s],
        ticksEverySecond: true);
  }
  if (left < const Duration(days: 7)) {
    return Countdown(CountdownState.running, [d, h, m]);
  }
  return Countdown(CountdownState.running, [d, h]);
}
