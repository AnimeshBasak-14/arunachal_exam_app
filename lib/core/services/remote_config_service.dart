import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService.instance;
});

class RemoteConfigService {
  static final RemoteConfigService instance = RemoteConfigService._internal();
  factory RemoteConfigService() => instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;

  // Remote Config Keys
  static const String keyShowExamBanner = 'show_exam_banner';
  static const String keyExamBannerTitle = 'exam_banner_title';
  static const String keyExamBannerSubtitle = 'exam_banner_subtitle';
  static const String keyExamBannerActionUrl = 'exam_banner_action_url';
  static const String keyDailyChallengeSubject = 'daily_challenge_subject';
  static const String keyMinAppVersion = 'min_app_version';
  static const String keyDailyTestQuestionCount = 'daily_test_question_count';
  static const String keyDailyChallengeTheme = 'daily_challenge_theme';
  static const String keyDailyMockLimit = 'daily_mock_limit';
  static const String keyWeeklyMegaMockActive = 'weekly_mega_mock_active';
  static const String keyWeeklyMegaMockTitle = 'weekly_mega_mock_title';
  static const String keyTrophiesMultiplier = 'trophies_multiplier';

  // In-app defaults
  static const Map<String, dynamic> _defaults = {
    keyShowExamBanner: true,
    keyExamBannerTitle: '📢 APSSB CGL & CHSL 2026 Updates',
    keyExamBannerSubtitle:
        'New PYQ Papers & Mock Tests uploaded! Test your speed & score higher.',
    keyExamBannerActionUrl: '',
    keyDailyChallengeSubject: 'General Knowledge & Current Affairs',
    keyMinAppVersion: '1.0.0',
    keyDailyTestQuestionCount: 10,
    keyDailyChallengeTheme: 'Daily APSSB Sprint',
    keyDailyMockLimit: 3,
    keyWeeklyMegaMockActive: false,
    keyWeeklyMegaMockTitle: '🎯 Weekend APSSB Grand Mock Challenge',
    keyTrophiesMultiplier: 1.0,
  };

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) return;

      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );

      await _remoteConfig!.setDefaults(_defaults);
      await _remoteConfig!.fetchAndActivate();

      debugPrint(
          '[RemoteConfig] Initialized & fetched successfully. show_exam_banner: $showExamBanner, qCount: $dailyTestQuestionCount');
    } catch (e) {
      debugPrint('[RemoteConfig] Initialization error (using defaults): $e');
    }
  }

  bool get showExamBanner {
    try {
      return _remoteConfig?.getBool(keyShowExamBanner) ??
          (_defaults[keyShowExamBanner] as bool);
    } catch (_) {
      return true;
    }
  }

  String get examBannerTitle {
    try {
      final title = _remoteConfig?.getString(keyExamBannerTitle);
      return (title != null && title.isNotEmpty)
          ? title
          : (_defaults[keyExamBannerTitle] as String);
    } catch (_) {
      return _defaults[keyExamBannerTitle] as String;
    }
  }

  String get examBannerSubtitle {
    try {
      final sub = _remoteConfig?.getString(keyExamBannerSubtitle);
      return (sub != null && sub.isNotEmpty)
          ? sub
          : (_defaults[keyExamBannerSubtitle] as String);
    } catch (_) {
      return _defaults[keyExamBannerSubtitle] as String;
    }
  }

  String get examBannerActionUrl {
    try {
      return _remoteConfig?.getString(keyExamBannerActionUrl) ?? '';
    } catch (_) {
      return '';
    }
  }

  String get dailyChallengeSubject {
    try {
      final sub = _remoteConfig?.getString(keyDailyChallengeSubject);
      return (sub != null && sub.isNotEmpty)
          ? sub
          : (_defaults[keyDailyChallengeSubject] as String);
    } catch (_) {
      return _defaults[keyDailyChallengeSubject] as String;
    }
  }

  int get dailyTestQuestionCount {
    try {
      final val = _remoteConfig?.getInt(keyDailyTestQuestionCount);
      return (val != null && val > 0)
          ? val
          : (_defaults[keyDailyTestQuestionCount] as int);
    } catch (_) {
      return _defaults[keyDailyTestQuestionCount] as int;
    }
  }

  String get dailyChallengeTheme {
    try {
      final theme = _remoteConfig?.getString(keyDailyChallengeTheme);
      return (theme != null && theme.isNotEmpty)
          ? theme
          : (_defaults[keyDailyChallengeTheme] as String);
    } catch (_) {
      return _defaults[keyDailyChallengeTheme] as String;
    }
  }

  int get dailyMockLimit {
    try {
      final val = _remoteConfig?.getInt(keyDailyMockLimit);
      return (val != null && val > 0)
          ? val
          : (_defaults[keyDailyMockLimit] as int);
    } catch (_) {
      return _defaults[keyDailyMockLimit] as int;
    }
  }

  bool get weeklyMegaMockActive {
    try {
      return _remoteConfig?.getBool(keyWeeklyMegaMockActive) ??
          (_defaults[keyWeeklyMegaMockActive] as bool);
    } catch (_) {
      return _defaults[keyWeeklyMegaMockActive] as bool;
    }
  }

  String get weeklyMegaMockTitle {
    try {
      final title = _remoteConfig?.getString(keyWeeklyMegaMockTitle);
      return (title != null && title.isNotEmpty)
          ? title
          : (_defaults[keyWeeklyMegaMockTitle] as String);
    } catch (_) {
      return _defaults[keyWeeklyMegaMockTitle] as String;
    }
  }

  double get trophiesMultiplier {
    try {
      final val = _remoteConfig?.getDouble(keyTrophiesMultiplier);
      return (val != null && val > 0.0)
          ? val
          : (_defaults[keyTrophiesMultiplier] as double);
    } catch (_) {
      return _defaults[keyTrophiesMultiplier] as double;
    }
  }
}
