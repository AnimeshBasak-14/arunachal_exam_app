import 'package:arunachal_exam_app/features/plan/data/countdown.dart';
import 'package:flutter_test/flutter_test.dart';

String show(Countdown c) =>
    c.segments.map((s) => '${s.value} ${s.label}').join(' : ');

void main() {
  final exam = DateTime(2026, 12, 16);

  test('1 month or more shows MONTHS : DAYS', () {
    final c = examCountdown(DateTime(2026, 10, 30, 10, 0), exam);
    expect(c.state, CountdownState.running);
    // 30 Oct 10:00 + 1 month = 30 Nov 10:00; 16 Dec 00:00 is 15 days 14 hours later.
    expect(show(c), '01 MONTH : 15 DAYS');
    expect(c.ticksEverySecond, isFalse);
  });

  test('several months', () {
    final c = examCountdown(DateTime(2026, 6, 16, 9), DateTime(2026, 12, 16));
    expect(show(c), startsWith('05 MONTHS'));
  });

  test('exactly one month out', () {
    final c = examCountdown(DateTime(2026, 11, 16), exam);
    expect(show(c), '01 MONTH : 00 DAYS');
  });

  test('month end does not overshoot (31 Jan to 28 Feb style)', () {
    final c = examCountdown(DateTime(2026, 1, 31, 8), DateTime(2026, 3, 1));
    expect(c.segments.first.label, 'MONTH');
    expect(c.segments.first.value, '01');
  });

  test('under a month, 7+ days shows DAYS : HOURS', () {
    final c = examCountdown(DateTime(2026, 12, 2, 18, 30), exam);
    expect(show(c), '13 DAYS : 05 HRS');
    expect(c.ticksEverySecond, isFalse);
  });

  test('exactly 7 days is still DAYS : HOURS', () {
    expect(
        show(examCountdown(DateTime(2026, 12, 9), exam)), '07 DAYS : 00 HRS');
  });

  test('under 7 days shows DAYS : HOURS : MINUTES', () {
    final c = examCountdown(DateTime(2026, 12, 11, 20, 45), exam);
    expect(show(c), '04 DAYS : 03 HRS : 15 MIN');
    expect(c.ticksEverySecond, isFalse);
  });

  test('under 3 days shows seconds and ticks every second', () {
    final c = examCountdown(DateTime(2026, 12, 14, 23, 59, 30), exam);
    expect(show(c), '01 DAY : 00 HRS : 00 MIN : 30 SEC');
    expect(c.ticksEverySecond, isTrue);
  });

  test('exactly 3 days is minutes, just under is seconds', () {
    expect(examCountdown(DateTime(2026, 12, 13), exam).segments.length, 3);
    expect(examCountdown(DateTime(2026, 12, 13, 0, 0, 1), exam).segments.length,
        4);
  });

  test('exam day and passed dates', () {
    expect(examCountdown(DateTime(2026, 12, 16, 8), exam).state,
        CountdownState.examDay);
    expect(examCountdown(DateTime(2026, 12, 17), exam).state,
        CountdownState.passed);
    expect(examCountdown(DateTime(2027, 1, 1), exam).segments, isEmpty);
  });

  test('time of the exam date argument is ignored', () {
    final a =
        examCountdown(DateTime(2026, 12, 2), DateTime(2026, 12, 16, 23, 59));
    final b = examCountdown(DateTime(2026, 12, 2), DateTime(2026, 12, 16));
    expect(show(a), show(b));
  });
}
