import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/exam_repository.dart';
import '../../../core/services/question_repository.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/streak_service.dart';
import '../../exam/data/attempt.dart';
import '../../papers/data/paper.dart';
import 'coins.dart';
import 'day_key.dart';
import 'questions_today.dart';

/// Questions that can be shown as plain text with an answer key. Anything
/// that needs a figure or a passage is left out of the daily question.
bool isDailyEligible(Question q) =>
    q.hasAnswerKey &&
    q.options.length >= 2 &&
    q.questionText.trim().length >= 15 &&
    !q.hasImage &&
    (q.questionImage ?? '').isEmpty &&
    (q.passageOrDirection ?? '').trim().isEmpty &&
    (q.passageImage ?? '').isEmpty &&
    q.optionImages.every((i) => i == null || i.isEmpty);

/// Same item for the same date, for everyone, with no server involved.
T? pickForDay<T>(List<T> items, int day, {int salt = 0}) =>
    items.isEmpty ? null : items[((day * 7919) + salt).abs() % items.length];

/// The PYQ of the day. The choice is cached per date, so reopening a day
/// always shows the same question, even if papers change later.
final dailyQuestionProvider =
    FutureProvider.family<Question?, String>((ref, date) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final cacheKey = 'daily_q_$date';
  final cached = prefs.getString(cacheKey);
  if (cached != null) {
    try {
      final m = jsonDecode(cached) as Map<String, dynamic>;
      return Question.fromMap(m['id']?.toString() ?? '', m);
    } catch (_) {}
  }

  final day = parseDayKey(date);
  if (day == null) return null;
  final n = dayNumber(day);
  final result = await ref.watch(papersProvider(PaperKind.pyq).future);
  final papers = result.papers.where((p) => p.questionCount >= 5).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  if (papers.isEmpty) return null;

  // Try a few papers in case the first has no suitable text-only question.
  for (int attempt = 0; attempt < papers.length.clamp(0, 5); attempt++) {
    final paper = papers[(n + attempt) % papers.length];
    final qs = await ExamRepository.instance.fetchQuestionsForTest(paper.id);
    final q = pickForDay(qs.where(isDailyEligible).toList(), n);
    if (q != null) {
      try {
        await prefs.setString(cacheKey, jsonEncode(Attempt.questionToMap(q)));
      } catch (e) {
        debugPrint('[daily] cache failed: $e');
      }
      return q;
    }
  }
  return null;
});

/// The mock of the day: a different mock each date.
final dailyMockProvider =
    FutureProvider.family<Paper?, String>((ref, date) async {
  final day = parseDayKey(date);
  if (day == null) return null;
  final result = await ref.watch(papersProvider(PaperKind.mock).future);
  final mocks = result.papers.where((p) => p.questionCount >= 10).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  return pickForDay(mocks, dayNumber(day), salt: 3);
});

class DailyResult {
  final String picked; // 'a'..'d'
  final bool correct;
  const DailyResult(this.picked, this.correct);
}

class DailyLogNotifier extends Notifier<Map<String, DailyResult>> {
  static const _key = 'daily_log_v1';

  @override
  Map<String, DailyResult> build() {
    try {
      final raw = jsonDecode(
              ref.read(sharedPreferencesProvider).getString(_key) ?? '{}')
          as Map<String, dynamic>;
      return {
        for (final e in raw.entries)
          e.key: DailyResult(e.value['p'] as String, e.value['c'] as bool)
      };
    } catch (_) {
      return {};
    }
  }

  /// Records an answer once per date. For today it also counts as studying
  /// (streak) and earns coins. Earlier days are practice only, so old
  /// questions can't be farmed for coins.
  void answer(String date, String picked, bool correct, {DateTime? now}) {
    if (state.containsKey(date)) return;
    state = {...state, date: DailyResult(picked, correct)};
    if (date == dayKey(now ?? DateTime.now())) {
      ref.read(questionsTodayProvider.notifier).add(1);
    }
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(
        _key,
        jsonEncode({
          for (final e in state.entries)
            e.key: {'p': e.value.picked, 'c': e.value.correct}
        }));
    final today = dayKey(now ?? DateTime.now());
    if (date == today) {
      StreakService(prefs).checkAndUpdateStreak();
      ref.read(coinsProvider.notifier).award(
            'daily:$date',
            correct ? CoinReward.dailyCorrect : CoinReward.dailyTried,
            'PYQ of the day',
          );
    }
  }
}

final dailyLogProvider =
    NotifierProvider<DailyLogNotifier, Map<String, DailyResult>>(
        DailyLogNotifier.new);
