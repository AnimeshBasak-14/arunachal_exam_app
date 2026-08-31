class AppConstants {
  AppConstants._();

  // Gemini AI API Key
  // TODO: Before production - restrict this key in Google Cloud Console
  // to your Android package name: com.example.arunachal_exam_app
  // Get a free key at: https://aistudio.google.com
  static const String geminiApiKey = 'AQ.Ab8RN6Ky-8kYGX5P-nvgh7Dzc914_oECI-4-kaCo4nTBAkimdA';
  static const String fallbackApiKey = 'AIzaSyC8KsvkrcI1RkelPfPxqeHzzC8H-PBENPk';

  // Valid Gemini keys start with 'AIzaSy'
  static String get effectiveGeminiApiKey {
    if (geminiApiKey.startsWith('AIzaSy')) {
      return geminiApiKey;
    }
    return fallbackApiKey;
  }

  // App info
  static const String appName = 'Arunachal Exam Prep';
  static const String appVersion = '1.0.0';

  // Streak keys (SharedPreferences)
  static const String streakCountKey = 'streak_count';
  static const String streakLastDateKey = 'streak_last_date';
  static const String streakLongestKey = 'streak_longest';

  // Notification IDs
  static const int dailyStreakNotifId = 1001;
  static const int wordOfDayNotifId = 1002;
}
