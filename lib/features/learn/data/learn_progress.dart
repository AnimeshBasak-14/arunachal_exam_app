import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/streak_service.dart';
import '../../plan/data/study_plan_provider.dart';

/// Default daily card goal if no custom plan is set.
const dailyCardGoal = 20;

class LearnProgress {
  final int xp;
  final int today; // cards finished today
  final int combo; // correct answers in a row
  final int bestCombo;
  final Set<String> saved;
  final Set<String> known; // answered right at least once

  const LearnProgress({
    this.xp = 0,
    this.today = 0,
    this.combo = 0,
    this.bestCombo = 0,
    this.saved = const {},
    this.known = const {},
  });

  LearnProgress copyWith({int? xp, int? today, int? combo, int? bestCombo, Set<String>? saved, Set<String>? known}) =>
      LearnProgress(
        xp: xp ?? this.xp,
        today: today ?? this.today,
        combo: combo ?? this.combo,
        bestCombo: bestCombo ?? this.bestCombo,
        saved: saved ?? this.saved,
        known: known ?? this.known,
      );
}

class LearnProgressNotifier extends Notifier<LearnProgress> {
  static const _k = 'learn.';
  SharedPreferences get _p => ref.read(sharedPreferencesProvider);

  String get _todayKey {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  @override
  LearnProgress build() {
    final p = _p;
    final sameDay = p.getString('${_k}day') == _todayKey;
    return LearnProgress(
      xp: p.getInt('${_k}xp') ?? 0,
      today: sameDay ? (p.getInt('${_k}today') ?? 0) : 0,
      bestCombo: p.getInt('${_k}best') ?? 0,
      saved: (p.getStringList('${_k}saved') ?? const []).toSet(),
      known: (p.getStringList('${_k}known') ?? const []).toSet(),
    );
  }

  /// A card was finished. Returns true when this completes the daily goal.
  bool finish({required int xp}) {
    final before = state.today;
    state = state.copyWith(xp: state.xp + xp, today: before + 1);
    _p
      ..setInt('${_k}xp', state.xp)
      ..setInt('${_k}today', state.today)
      ..setString('${_k}day', _todayKey);
    final goal = ref.read(dailyCardGoalProvider);
    final hitGoal = before < goal && state.today >= goal;
    if (hitGoal) StreakService(_p).checkAndUpdateStreak();
    return hitGoal;
  }

  void answered(String id, {required bool correct}) {
    final combo = correct ? state.combo + 1 : 0;
    final best = combo > state.bestCombo ? combo : state.bestCombo;
    state = state.copyWith(
      combo: combo,
      bestCombo: best,
      known: correct ? {...state.known, id} : state.known,
    );
    _p
      ..setInt('${_k}best', best)
      ..setStringList('${_k}known', state.known.toList());
  }

  void toggleSave(String id) {
    final s = {...state.saved};
    s.contains(id) ? s.remove(id) : s.add(id);
    state = state.copyWith(saved: s);
    _p.setStringList('${_k}saved', s.toList());
  }
}

final learnProgressProvider =
    NotifierProvider<LearnProgressNotifier, LearnProgress>(LearnProgressNotifier.new);
