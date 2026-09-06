import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arunachal_exam_app/core/services/firebase_service.dart';

class MockFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  bool shouldThrow = false;
  String? loggedScreenName;
  int logScreenViewCallCount = 0;

  @override
  Future<void> logScreenView({
    String? screenClass,
    String? screenName,
    AnalyticsCallOptions? callOptions,
    Map<String, Object?>? parameters,
  }) async {
    logScreenViewCallCount++;
    if (shouldThrow) {
      throw Exception('Analytics error occurred');
    }
    loggedScreenName = screenName;
  }
}

class MockFirebaseFirestore extends Fake implements FirebaseFirestore {}

void main() {
  group('FirebaseService - logScreenView', () {
    late MockFirebaseAnalytics mockAnalytics;
    late MockFirebaseFirestore mockFirestore;
    late FirebaseService firebaseService;

    setUp(() {
      mockAnalytics = MockFirebaseAnalytics();
      mockFirestore = MockFirebaseFirestore();
      firebaseService = FirebaseService(
        analytics: mockAnalytics,
        firestore: mockFirestore,
      );
    });

    test('successfully logs screen view when analytics call succeeds', () async {
      const screenName = 'HomeScreen';

      await firebaseService.logScreenView(screenName);

      expect(mockAnalytics.logScreenViewCallCount, equals(1));
      expect(mockAnalytics.loggedScreenName, equals(screenName));
    });

    test('handles error gracefully when analytics throws an exception', () async {
      mockAnalytics.shouldThrow = true;
      const screenName = 'ErrorScreen';

      // Should complete without rethrowing or crashing
      await expectLater(
        firebaseService.logScreenView(screenName),
        completes,
      );

      expect(mockAnalytics.logScreenViewCallCount, equals(1));
    });
  });
}
