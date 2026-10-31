import 'package:arunachal_exam_app/core/services/question_repository.dart';
import 'package:arunachal_exam_app/core/services/service_providers.dart';
import 'package:arunachal_exam_app/features/streak/data/coins.dart';
import 'package:arunachal_exam_app/features/streak/data/daily.dart';
import 'package:arunachal_exam_app/features/streak/data/day_key.dart';
import 'package:arunachal_exam_app/features/streak/data/time_tracker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> container(
    [Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
}

void main() {
  group('day keys', () {
    test('format and parse round-trip', () {
      expect(dayKey(DateTime(2026, 3, 5)), '2026-03-05');
      expect(parseDayKey('2026-03-05'), DateTime(2026, 3, 5));
    });

    test('rejects impossible and malformed dates', () {
      expect(parseDayKey('2026-02-31'), isNull);
      expect(parseDayKey('2026-13-01'), isNull);
      expect(parseDayKey('nonsense'), isNull);
      expect(parseDayKey('2026-3-5'), isNull);
    });

    test('day numbers are consecutive across month and year ends', () {
      expect(
          dayNumber(DateTime(2026, 1, 1)) - dayNumber(DateTime(2025, 12, 31)),
          1);
      expect(dayNumber(DateTime(2026, 3, 1)) - dayNumber(DateTime(2026, 2, 28)),
          1);
    });

    test('time of day does not change the day number', () {
      expect(dayNumber(DateTime(2026, 5, 1, 0, 1)),
          dayNumber(DateTime(2026, 5, 1, 23, 59)));
    });
  });

  group('pick of the day', () {
    test('same day gives the same item, other days vary', () {
      final items = List.generate(40, (i) => i);
      expect(pickForDay(items, 100), pickForDay(items, 100));
      final picks = {for (int d = 0; d < 30; d++) pickForDay(items, d)};
      expect(picks.length, greaterThan(15));
    });

    test('empty list gives null', () => expect(pickForDay(<int>[], 5), isNull));

    test('eligibility needs an answer key, options and plain text', () {
      Question q({
        String key = 'b',
        List<String>? options,
        String? image,
        String text = 'Which river is called the Siang in Arunachal?',
      }) =>
          Question(
            id: 'x',
            examCode: 'APPSC',
            year: 2023,
            subject: 'GK',
            questionText: text,
            options:
                options ?? const ['(a) Brahmaputra', '(b) Yarlung Tsangpo'],
            correctAnswer: key,
            officialAnswer: key,
            solution: '',
            questionImage: image,
          );
      expect(isDailyEligible(q()), isTrue);
      expect(isDailyEligible(q(key: '')), isFalse);
      expect(isDailyEligible(q(options: const ['only one'])), isFalse);
      expect(isDailyEligible(q(image: 'http://x/y.png')), isFalse);
      expect(isDailyEligible(q(text: 'short')), isFalse);
    });
  });

  group('coins', () {
    test('award once per key', () async {
      final c = await container();
      final n = c.read(coinsProvider.notifier);
      expect(n.award('k1', 10, 'a'), isTrue);
      expect(n.award('k1', 10, 'a'), isFalse);
      expect(c.read(coinsProvider).balance, 10);
      expect(n.award('k2', 3, 'b'), isTrue);
      expect(c.read(coinsProvider).balance, 13);
      expect(c.read(coinsProvider).events.first.reason, 'b');
    });

    test('balance persists across restarts', () async {
      final c = await container();
      c.read(coinsProvider.notifier).award('k1', 7, 'a');
      final prefs = c.read(sharedPreferencesProvider);
      final c2 = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      expect(c2.read(coinsProvider).balance, 7);
      expect(c2.read(coinsProvider.notifier).award('k1', 7, 'a'), isFalse);
    });

    test('zero or negative awards are ignored', () async {
      final c = await container();
      expect(c.read(coinsProvider.notifier).award('z', 0, 'a'), isFalse);
      expect(c.read(coinsProvider).balance, 0);
    });

    test(
        'hidden coins: three distinct spots, stable per day, varying across days',
        () {
      final d = DateTime(2026, 11, 2);
      final spots = hiddenSpotsFor(d);
      expect(spots.length, 3);
      expect(spots.toSet().length, 3);
      expect(hiddenSpotsFor(DateTime(2026, 11, 2, 18)), spots);
      final seen = {
        for (int i = 0; i < 20; i++)
          hiddenSpotsFor(DateTime(2026, 11, 1 + i)).join(',')
      };
      expect(seen.length, greaterThan(5));
      expect(hiddenSpotsFor(d).every(hiddenCoinSpots.contains), isTrue);
    });
  });

  group('daily answers', () {
    test('todays answer earns coins and streak once', () async {
      final c = await container();
      final today = dayKey(DateTime.now());
      c.read(dailyLogProvider.notifier).answer(today, 'b', true);
      expect(c.read(coinsProvider).balance, CoinReward.dailyCorrect);
      c.read(dailyLogProvider.notifier).answer(today, 'a', false); // ignored
      expect(c.read(coinsProvider).balance, CoinReward.dailyCorrect);
      expect(c.read(dailyLogProvider)[today]!.correct, isTrue);
      await pumpEventQueue();
      expect(c.read(sharedPreferencesProvider).getInt('streak_count'), 1);
    });

    test('a wrong answer still earns the smaller reward', () async {
      final c = await container();
      c
          .read(dailyLogProvider.notifier)
          .answer(dayKey(DateTime.now()), 'a', false);
      expect(c.read(coinsProvider).balance, CoinReward.dailyTried);
    });

    test('past days are practice only: no coins, no streak', () async {
      final c = await container();
      final past = dayKey(DateTime.now().subtract(const Duration(days: 3)));
      c.read(dailyLogProvider.notifier).answer(past, 'b', true);
      await pumpEventQueue();
      expect(c.read(coinsProvider).balance, 0);
      expect(c.read(sharedPreferencesProvider).getInt('streak_count'), isNull);
      expect(c.read(dailyLogProvider).containsKey(past), isTrue);
    });
  });

  group('time tracker', () {
    test('accumulates by section and sub-section', () async {
      SharedPreferences.setMockInitialValues({});
      final t = TimeTracker(await SharedPreferences.getInstance());
      final now = DateTime(2026, 11, 2, 10);
      t.add('cards', 'grammar', 120, now: now);
      t.add('cards', 'grammar', 30, now: now);
      t.add('cards', 'polity', 60, now: now);
      t.add('pyq', 'paper', 300, now: now);
      final d = t.lastDays(1, now: now);
      expect(d['cards']!['grammar'], 150);
      expect(TimeTracker.sectionTotal(d, 'cards'), 210);
      expect(TimeTracker.sectionTotal(d, 'pyq'), 300);
      expect(TimeTracker.sectionTotal(d, 'mock'), 0);
    });

    test('ranges include only the requested days', () async {
      SharedPreferences.setMockInitialValues({});
      final t = TimeTracker(await SharedPreferences.getInstance());
      final now = DateTime(2026, 11, 10);
      t.add('pyq', 'paper', 100, now: DateTime(2026, 11, 10));
      t.add('pyq', 'paper', 100, now: DateTime(2026, 11, 7));
      t.add('pyq', 'paper', 100, now: DateTime(2026, 11, 2));
      expect(TimeTracker.sectionTotal(t.lastDays(1, now: now), 'pyq'), 100);
      expect(TimeTracker.sectionTotal(t.lastDays(7, now: now), 'pyq'), 200);
      expect(TimeTracker.sectionTotal(t.lastDays(30, now: now), 'pyq'), 300);
    });

    test('zero or negative seconds are ignored; old days are pruned', () async {
      SharedPreferences.setMockInitialValues({});
      final t = TimeTracker(await SharedPreferences.getInstance());
      t.add('pyq', 'paper', 0);
      t.add('pyq', 'paper', -5);
      expect(t.lastDays(7), isEmpty);
      final start = DateTime(2026, 1, 1);
      for (int i = 0; i < TimeTracker.keepDays + 10; i++) {
        t.add('pyq', 'paper', 5, now: start.add(Duration(days: i)));
      }
      final last = start.add(Duration(days: TimeTracker.keepDays + 9));
      final all = t.lastDays(TimeTracker.keepDays + 10, now: last);
      expect(TimeTracker.sectionTotal(all, 'pyq'), TimeTracker.keepDays * 5);
    });
  });
}
