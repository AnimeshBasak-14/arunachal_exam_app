import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arunachal_exam_app/core/services/firebase_service.dart';
import 'package:arunachal_exam_app/core/services/service_providers.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

/// Creates a test [ProviderContainer] and disposes it at tear down.
ProviderContainer createContainer({
  ProviderContainer? parent,
  List<Override> overrides = const [],
  List<ProviderObserver>? observers,
}) {
  final container = ProviderContainer(
    parent: parent,
    overrides: overrides,
    observers: observers,
  );
  addTearDown(container.dispose);
  return container;
}

/// Cached paper lists, as the app saves them after a successful fetch.
const cachedPyqs = '''[
  {"id":"p1","kind":"pyq","title":"APSSB CGL 2024 Solved Paper","exam_code":"APSSB-CGLE-2024","year":2024,"shift":"1","question_count":54,"total_questions":100,"duration_minutes":120},
  {"id":"p2","kind":"pyq","title":"APPSC Combined Competitive Exam Prelims Paper I","exam_code":"APPSC-CCE","year":2023,"question_count":100,"total_questions":100,"duration_minutes":120},
  {"id":"p3","kind":"pyq","title":"Arunachal Police Constable Written Test","exam_code":"AP-POLICE-CONSTABLE","year":null,"question_count":80},
  {"id":"ghost","kind":"pyq","title":"Empty Ghost Paper","exam_code":"APSSB-GHOST","year":2024,"question_count":0,"total_questions":100}
]''';

const cachedMocks = '''[
  {"id":"m1","kind":"mock","title":"APSSB Full Mock 1","exam_code":"APSSB-MOCK","question_count":50,"duration_minutes":60,"difficulty":"Medium"}
]''';

/// Sets the phone-sized viewport used across layout tests.
void phoneViewport(WidgetTester tester, {Size size = const Size(360, 780)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<SharedPreferences> testPrefs([Map<String, Object> extra = const {}]) async {
  SharedPreferences.setMockInitialValues({
    'cached_papers_pyq_v3': cachedPyqs,
    'cached_papers_mock_v3': cachedMocks,
    ...extra,
  });
  return SharedPreferences.getInstance();
}

List<Override> testOverrides(SharedPreferences prefs) => [
      sharedPreferencesProvider.overrideWithValue(prefs),
      firebaseServiceProvider.overrideWithValue(MockFirebaseService()),
    ];

/// Wraps [child] with 130% text, the owner's phone setting.
Widget scaled(Widget child, {double scale = 1.3}) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child,
      ),
    );

/// Pumps frames without waiting for endless animations (spinners, timers).
Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
