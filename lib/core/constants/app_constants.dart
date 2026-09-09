class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Arunachal Exam Prep';
  static const String appVersion = '1.3.0';

  // Streak keys (SharedPreferences)
  static const String streakCountKey = 'streak_count';
  static const String streakLastDateKey = 'streak_last_date';
  static const String streakLongestKey = 'streak_longest';
  static const String streakHistoryKey = 'streak_date_history';

  // Notification IDs
  static const int dailyStreakNotifId = 1001;
  static const int wordOfDayNotifId = 1002;
}
