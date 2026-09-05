import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arunachal_exam_app/main.dart';
import 'package:arunachal_exam_app/core/services/service_providers.dart';
import 'package:arunachal_exam_app/core/constants/app_strings.dart';

void main() {
  testWidgets('App starts with onboarding screen test', (WidgetTester tester) async {
    // Setup mock values for SharedPreferences
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': false,
      'is_logged_in': false,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );

    // Let the GoRouter redirect resolve
    await tester.pumpAndSettle();

    // Assert that the first page of onboarding is loaded
    expect(find.text(AppStrings.onboarding1Title), findsOneWidget);
  });
}
