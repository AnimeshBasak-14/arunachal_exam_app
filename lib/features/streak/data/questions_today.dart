import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/service_providers.dart';
import 'day_key.dart';

/// How many questions the student has answered today, across Learn cards,
/// the PYQ of the day, papers, mocks and the timed English test. Resets each
/// day. Compared with the daily question target from the study plan.
class QuestionsTodayNotifier extends Notifier<int> {
  static const _countKey = 'questions_today_count';
  static const _dayKey = 'questions_today_day';

  @override
  int build() {
    final p = ref.read(sharedPreferencesProvider);
    return p.getString(_dayKey) == dayKey(DateTime.now())
        ? (p.getInt(_countKey) ?? 0)
        : 0;
  }

  void add(int n, {DateTime? now}) {
    if (n <= 0) return;
    final p = ref.read(sharedPreferencesProvider);
    final today = dayKey(now ?? DateTime.now());
    final base = p.getString(_dayKey) == today ? (p.getInt(_countKey) ?? 0) : 0;
    state = base + n;
    p
      ..setString(_dayKey, today)
      ..setInt(_countKey, state);
  }
}

final questionsTodayProvider =
    NotifierProvider<QuestionsTodayNotifier, int>(QuestionsTodayNotifier.new);
