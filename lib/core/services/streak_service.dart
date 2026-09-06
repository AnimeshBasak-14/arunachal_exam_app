import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StreakService {
  final SharedPreferences _prefs;

  StreakService(this._prefs);

  int getCurrentStreak() => _prefs.getInt(AppConstants.streakCountKey) ?? 0;
  int getLongestStreak() => _prefs.getInt(AppConstants.streakLongestKey) ?? 0;
  String? getLastActiveDate() =>
      _prefs.getString(AppConstants.streakLastDateKey);

  List<String> getActiveDatesHistory() =>
      _prefs.getStringList('streak_active_dates_history') ?? [];

  Future<void> checkAndUpdateStreak() async {
    final today = _todayString();
    final lastDate = getLastActiveDate();

    // Ensure today is added to history
    final history = getActiveDatesHistory();
    if (!history.contains(today)) {
      history.add(today);
      await _prefs.setStringList('streak_active_dates_history', history);
    }

    if (lastDate == today) {
      // Already checked in today — no change
      return;
    }

    int currentStreak = getCurrentStreak();

    if (lastDate == null) {
      // First ever open
      currentStreak = 1;
    } else {
      final last = DateTime.tryParse(lastDate);
      final todayDt = DateTime.now();
      if (last != null) {
        final diff = todayDt
            .difference(DateTime(last.year, last.month, last.day))
            .inDays;
        if (diff == 1) {
          // Consecutive day
          currentStreak += 1;
        } else if (diff > 1) {
          // Missed one or more days — reset
          currentStreak = 1;
        }
        // diff == 0 handled above (same day)
      }
    }

    final longest = getLongestStreak();
    final writes = <Future<bool>>[
      _prefs.setInt(AppConstants.streakCountKey, currentStreak),
      _prefs.setString(AppConstants.streakLastDateKey, today),
    ];
    if (currentStreak > longest) {
      writes.add(_prefs.setInt(AppConstants.streakLongestKey, currentStreak));
    }
    await Future.wait(writes);
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
