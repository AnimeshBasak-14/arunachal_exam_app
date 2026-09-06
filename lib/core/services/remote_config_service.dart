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

  // In-app defaults
  static const Map<String, dynamic> _defaults = {
    keyShowExamBanner: true,
    keyExamBannerTitle: '📢 APSSB CGL & CHSL 2026 Updates',
    keyExamBannerSubtitle:
        'New PYQ Papers & Mock Tests uploaded! Test your speed & score higher.',
    keyExamBannerActionUrl: '',
    keyDailyChallengeSubject: 'General Knowledge & Current Affairs',
    keyMinAppVersion: '1.0.0',
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
          '[RemoteConfig] Initialized & fetched successfully. show_exam_banner: $showExamBanner');
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
}
