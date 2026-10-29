import 'package:flutter_test/flutter_test.dart';
import 'package:arunachal_exam_app/features/exam/data/attempt.dart';
import 'package:arunachal_exam_app/features/exam/data/result_comparison.dart';

void main() {
  Attempt makeAttempt({
    required String examCode,
    String mode = 'exam',
    required double score,
    required double maxScore,
    String date = '2026-10-29 10:00',
  }) {
    return Attempt(
      title: examCode,
      examCode: examCode,
      mode: mode,
      score: score,
      maxScore: maxScore,
      correct: score.toInt(),
      wrong: (maxScore - score).toInt(),
      left: 0,
      ungraded: 0,
      timeTaken: 120,
      date: date,
      ratingChange: 0,
      speedBonus: 0,
      selected: const {},
      questions: const [],
      raw: const {},
    );
  }

  group('ResultComparison compare', () {
    test('first attempt has no previous comparison', () {
      final cur = makeAttempt(examCode: 'APSSB-CGL', score: 60, maxScore: 100);
      final res = compare(cur, const []);

      expect(res.isFirstAttempt, isTrue);
      expect(res.previous, isNull);
      expect(res.deltaPoints, isNull);
      expect(res.isPersonalBest, isFalse);
      expect(res.deltaHeadline, 'First attempt. This is your starting point.');
      expect(res.deltaSubline, isNull);
      expect(res.recentAttempts, [cur]);
    });

    test('detects improvement and computes delta percentage points', () {
      final prev = makeAttempt(examCode: 'APSSB-CGL', score: 50, maxScore: 100, date: '2026-10-20');
      final cur = makeAttempt(examCode: 'APSSB-CGL', score: 65, maxScore: 100, date: '2026-10-29');

      final res = compare(cur, [prev]);

      expect(res.isFirstAttempt, isFalse);
      expect(res.previous, prev);
      expect(res.deltaPoints, 15);
      expect(res.deltaHeadline, '+15 points since your last APSSB-CGL attempt');
      expect(res.deltaSubline, isNull);
      expect(res.isPersonalBest, isTrue);
      expect(res.recentAttempts, [prev, cur]);
    });

    test('detects score drop with calm guidance message', () {
      final prev = makeAttempt(examCode: 'APSSB-CGL', score: 70, maxScore: 100, date: '2026-10-20');
      final cur = makeAttempt(examCode: 'APSSB-CGL', score: 62, maxScore: 100, date: '2026-10-29');

      final res = compare(cur, [prev]);

      expect(res.deltaPoints, -8);
      expect(res.deltaHeadline, '-8 points since your last APSSB-CGL attempt');
      expect(res.deltaSubline, 'A dip is normal. Review the questions you missed.');
      expect(res.isPersonalBest, isFalse);
    });

    test('detects identical score percentage', () {
      final prev = makeAttempt(examCode: 'APSSB-CGL', score: 50, maxScore: 100, date: '2026-10-20');
      // 25 / 50 is also 50%
      final cur = makeAttempt(examCode: 'APSSB-CGL', score: 25, maxScore: 50, date: '2026-10-29');

      final res = compare(cur, [prev]);

      expect(res.deltaPoints, 0);
      expect(res.deltaHeadline, 'Same as last time');
      expect(res.deltaSubline, isNull);
    });

    test('ignores attempts with different examCode', () {
      final other = makeAttempt(examCode: 'APPSC-CCE', score: 90, maxScore: 100);
      final cur = makeAttempt(examCode: 'APSSB-CGL', score: 60, maxScore: 100);

      final res = compare(cur, [other]);
      expect(res.isFirstAttempt, isTrue);
      expect(res.previous, isNull);
    });

    test('ignores attempts with maxScore == 0', () {
      final unverified = makeAttempt(examCode: 'APSSB-CGL', score: 0, maxScore: 0);
      final cur = makeAttempt(examCode: 'APSSB-CGL', score: 60, maxScore: 100);

      final res = compare(cur, [unverified]);
      expect(res.isFirstAttempt, isTrue);
    });

    test('keeps study mode vs exam mode separate', () {
      final study = makeAttempt(examCode: 'APSSB-CGL', mode: 'study', score: 90, maxScore: 100);
      final cur = makeAttempt(examCode: 'APSSB-CGL', mode: 'exam', score: 60, maxScore: 100);

      final res = compare(cur, [study]);
      expect(res.isFirstAttempt, isTrue);
      expect(res.previous, isNull);
    });

    test('safely handles if current attempt is already present in history list', () {
      final prev = makeAttempt(examCode: 'APSSB-CGL', score: 50, maxScore: 100, date: '2026-10-20');
      final cur = makeAttempt(examCode: 'APSSB-CGL', score: 70, maxScore: 100, date: '2026-10-29');

      // History has [cur, prev]
      final res = compare(cur, [cur, prev]);
      expect(res.isFirstAttempt, isFalse);
      expect(res.previous, prev);
      expect(res.deltaPoints, 20);
    });

    test('limits recent trend to up to 5 attempts chronologically', () {
      final a1 = makeAttempt(examCode: 'APSSB-CGL', score: 40, maxScore: 100, date: '2026-10-01');
      final a2 = makeAttempt(examCode: 'APSSB-CGL', score: 50, maxScore: 100, date: '2026-10-05');
      final a3 = makeAttempt(examCode: 'APSSB-CGL', score: 60, maxScore: 100, date: '2026-10-10');
      final a4 = makeAttempt(examCode: 'APSSB-CGL', score: 65, maxScore: 100, date: '2026-10-15');
      final a5 = makeAttempt(examCode: 'APSSB-CGL', score: 70, maxScore: 100, date: '2026-10-20');
      final cur = makeAttempt(examCode: 'APSSB-CGL', score: 80, maxScore: 100, date: '2026-10-25');

      // Newest first in history
      final res = compare(cur, [a5, a4, a3, a2, a1]);
      // Recent attempts should be [a2, a3, a4, a5, cur] (5 total, oldest to newest)
      expect(res.recentAttempts.length, 5);
      expect(res.recentAttempts.first, a2);
      expect(res.recentAttempts.last, cur);
    });
  });
}
