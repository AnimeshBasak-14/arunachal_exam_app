import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arunachal_exam_app/core/theme/app_theme.dart';
import 'package:arunachal_exam_app/features/shell/view/app_shell.dart';
import '../helpers/test_app.dart';

Future<void> pumpShell(WidgetTester tester, {required ThemeData Function() theme, int tab = 0}) async {
  final prefs = await testPrefs({'exam_goal_id': 'apssb-cgl'});
  await tester.pumpWidget(ProviderScope(
    overrides: testOverrides(prefs),
    child: MaterialApp(
      theme: theme(),
      home: scaled(AppShell(initialTab: tab)),
    ),
  ));
  await settle(tester);
}

void main() {
  for (final (name, theme) in <(String, ThemeData Function())>[
    ('light', () => AppTheme.lightTheme),
    ('dark', () => AppTheme.darkTheme),
  ]) {
    group('$name theme at 360px and 130% text', () {
      testWidgets('dashboard shows goal, papers for the goal board, live mock', (tester) async {
        phoneViewport(tester);
        await pumpShell(tester, theme: theme);

        expect(find.text('APSSB Combined Graduate Level'), findsOneWidget);
        expect(find.text('Previous Year Papers'), findsOneWidget);
        expect(find.text('APSSB CGL 2024 Solved Paper'), findsOneWidget);
        expect(find.text('Empty Ghost Paper'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Police').first);
        await settle(tester, 4);
        expect(find.text('Arunachal Police Constable Written Test'), findsOneWidget);

        await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -500));
        await settle(tester, 4);
        expect(find.text('LIVE MOCK ARENA'), findsOneWidget);
        expect(find.text('Enroll in Mock'), findsOneWidget);

        await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -900));
        await settle(tester, 4);
        expect(find.text('Study shelf'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('PYQ library groups by year, filters, and clears search', (tester) async {
        phoneViewport(tester);
        await pumpShell(tester, theme: theme, tab: 1);

        expect(find.text('PYQ Library'), findsWidgets);
        expect(find.text('2024'), findsWidgets);
        expect(find.text('Empty Ghost Paper'), findsNothing);
        expect(find.textContaining('Incomplete · 54 of 100'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'zzz');
        await settle(tester, 3);
        expect(find.text('No matching papers'), findsOneWidget);
        await tester.tap(find.byTooltip('Clear search'));
        await settle(tester, 3);
        expect(find.text('No matching papers'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('paper sheet offers exam and study modes', (tester) async {
        phoneViewport(tester);
        await pumpShell(tester, theme: theme, tab: 1);
        await tester.enterText(find.byType(TextField), 'appsc');
        await settle(tester, 3);
        expect(find.text('APSSB CGL 2024 Solved Paper'), findsNothing);
        await tester.tap(find.text('APPSC Combined Competitive Exam Prelims Paper I'));
        await settle(tester, 6);
        expect(find.text('Begin exam mode'), findsOneWidget);
        expect(find.text('Study with answers'), findsOneWidget);
        expect(find.text('120 min'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('mock tests tab lists mocks and opens the practice builder', (tester) async {
        phoneViewport(tester);
        await pumpShell(tester, theme: theme, tab: 2);
        expect(find.text('Mock Tests'), findsWidgets);
        await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -700));
        await settle(tester, 4);
        expect(find.text('APSSB Full Mock 1'), findsOneWidget);
        await tester.ensureVisible(find.text('Build a practice set'));
        await settle(tester, 4);
        await tester.tap(find.text('Build a practice set'));
        await settle(tester, 6);
        expect(find.text('Start practice'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('performance tab shows an empty state with no history', (tester) async {
        phoneViewport(tester);
        await pumpShell(tester, theme: theme, tab: 3);
        expect(find.text('Your progress lives here'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('bottom bar switches tabs', (tester) async {
        phoneViewport(tester);
        await pumpShell(tester, theme: theme);
        await tester.tap(find.byIcon(CupertinoIcons.book));
        await settle(tester, 3);
        expect(find.text('PYQ Library'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
