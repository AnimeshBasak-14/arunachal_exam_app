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
    
    int trophiesToAward = 10; // Daily check-in
    
    // Check milestones
    final awardedMilestones = _prefs.getStringList('awarded_streak_milestones') ?? [];
    if (currentStreak >= 30 && !awardedMilestones.contains('30')) {
      trophiesToAward += 250;
      awardedMilestones.add('30');
    } else if (currentStreak >= 14 && !awardedMilestones.contains('14')) {
      trophiesToAward += 100;
      awardedMilestones.add('14');
    } else if (currentStreak >= 7 && !awardedMilestones.contains('7')) {
      trophiesToAward += 50;
      awardedMilestones.add('7');
    } else if (currentStreak >= 3 && !awardedMilestones.contains('3')) {
      trophiesToAward += 25;
      awardedMilestones.add('3');
    }
    
    // Clear milestones if streak resets
    if (currentStreak == 1) {
      awardedMilestones.clear();
    }
    writes.add(_prefs.setStringList('awarded_streak_milestones', awardedMilestones));
    
    // Save pending trophies to be claimed in UI
    final pendingTrophies = (_prefs.getInt('pending_streak_trophies') ?? 0) + trophiesToAward;
    writes.add(_prefs.setInt('pending_streak_trophies', pendingTrophies));

    await Future.wait(writes);
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
