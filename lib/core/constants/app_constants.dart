class AppConstants {
  AppConstants._();

  // Hugging Face API Token (starts with hf_...)
  // Get a free user token at: https://huggingface.co/settings/tokens
  static const String huggingFaceApiKey = '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';
  static const String huggingFaceModel = 'meta-llama/Llama-3.2-3B-Instruct';

  // App info
  static const String appName = 'Arunachal Exam Prep';
  static const String appVersion = '1.0.0';

  // Streak keys (SharedPreferences)
  static const String streakCountKey = 'streak_count';
  static const String streakLastDateKey = 'streak_last_date';
  static const String streakLongestKey = 'streak_longest';
  static const String streakHistoryKey = 'streak_date_history';

  // Notification IDs
  static const int dailyStreakNotifId = 1001;
  static const int wordOfDayNotifId = 1002;
}
