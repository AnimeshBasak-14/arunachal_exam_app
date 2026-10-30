import 'package:arunachal_exam_app/core/theme/app_theme.dart';
import 'package:arunachal_exam_app/data/state_gk_data.dart';
import 'package:arunachal_exam_app/features/account/view/account_screen.dart';
import 'package:arunachal_exam_app/features/home/view/state_gk_screen.dart';
import 'package:arunachal_exam_app/features/learn/data/card_photos.dart';
import 'package:arunachal_exam_app/features/syllabus/data/syllabus.dart';
import 'package:arunachal_exam_app/features/syllabus/view/syllabus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_app.dart';

Future<SharedPreferences> pump(WidgetTester tester, Widget page,
    [Map<String, Object> prefs = const {}]) async {
  phoneViewport(tester);
  final p = await testPrefs(prefs);
  await tester.pumpWidget(ProviderScope(
    overrides: testOverrides(p),
    child: MaterialApp(theme: AppTheme.lightTheme, home: scaled(page)),
  ));
  await settle(tester);
  return p;
}

void main() {
  testWidgets('shows only my exam, and ticking a topic is saved',
      (tester) async {
    final prefs = await pump(
        tester, const SyllabusScreen(), {'exam_goal_id': 'apssb-cgl'});
    expect(find.text('Combined Graduate Level (CGL)'), findsOneWidget);
    expect(find.text('Nothing ticked yet'), findsOneWidget);
    // Other exams are not listed on the page.
    expect(find.text('APPSCCE (Civil Services)'), findsNothing);

    await tester.tap(find.text('General Awareness'));
    await settle(tester);
    await tester.ensureVisible(find.text('Indian Polity'));
    await settle(tester);
    await tester.tap(find.text('Indian Polity'));
    await settle(tester);

    // The paper's counter moves from 0 to 1.
    expect(find.textContaining(RegExp(r'^1/\d+$')), findsOneWidget);
    final saved = prefs.getStringList(SyllabusDoneNotifier.key)!;
    expect(saved.single, endsWith('|Indian Polity'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('search opens another exam without changing mine',
      (tester) async {
    await pump(tester, const SyllabusScreen(), {'exam_goal_id': 'apssb-cgl'});
    await tester.tap(find.byTooltip('Other exams'));
    await settle(tester);
    expect(find.text('All syllabi'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'civil services');
    await settle(tester);
    await tester.tap(find.text('APPSCCE (Civil Services)'));
    await settle(tester);

    expect(find.text('APPSCCE (Civil Services)'), findsOneWidget);
    expect(find.text('Make it mine'), findsOneWidget);
    await tester.tap(find.text('Back to mine'));
    await settle(tester);
    expect(find.text('Combined Graduate Level (CGL)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a goal with several syllabi asks which one', (tester) async {
    final prefs = await pump(
        tester, const SyllabusScreen(), {'exam_goal_id': 'appsc-other'});
    expect(find.text('Which exam are you preparing for?'), findsOneWidget);
    await tester.ensureVisible(find.text('Junior Engineer (JE) Common Exam'));
    await settle(tester);
    await tester.tap(find.text('Junior Engineer (JE) Common Exam'));
    await settle(tester);
    expect(find.text('Which exam are you preparing for?'), findsNothing);
    expect(prefs.getString(MySyllabusNotifier.key),
        'Junior Engineer (JE) Common Exam');
    // Opens at the top of the chosen syllabus.
    expect(find.textContaining('YOUR SYLLABUS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chapter: Practise sits in the header, photos inside the text',
      (tester) async {
    final ch = StateGkData.chapters.firstWhere((c) => c.id == 'ch9');
    await pump(tester, ChapterScreen(chapter: ch));
    expect(find.text('Practise'), findsOneWidget);
    expect(find.text('Practise as cards'), findsNothing);
    // The first photos appear right after the opening paragraphs, not in a
    // block above the article.
    expect(find.text('Pictures'), findsNothing);
    expect(find.textContaining('Photo:'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card pictures switch is off by default and saves',
      (tester) async {
    final prefs = await pump(tester, const AccountScreen());
    await tester.scrollUntilVisible(find.text('Pictures on cards'), 200);
    final sw = find.byType(Switch);
    expect(tester.widget<Switch>(sw).value, isFalse);
    await tester.ensureVisible(sw);
    await settle(tester);
    await tester.tap(sw);
    await settle(tester);
    expect(prefs.getBool(CardPhotosNotifier.key), isTrue);
  });

  testWidgets('turning pictures on reveals the subject choices',
      (tester) async {
    final prefs = await pump(tester, const AccountScreen());
    await tester.scrollUntilVisible(find.text('Pictures on cards'), 200);
    expect(find.text('Show pictures in'.toUpperCase()), findsNothing);
    await tester.ensureVisible(find.byType(Switch));
    await settle(tester);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('SHOW PICTURES IN'), findsOneWidget);
    // English and vocabulary are never offered.
    expect(find.widgetWithText(FilterChip, 'History'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Environment'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Grammar'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Vocabulary'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Polity'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Polity'));
    await settle(tester);
    final saved = prefs.getStringList(CardPhotoTopicsNotifier.key)!;
    expect(saved, isNot(contains('polity')));
    expect(saved, contains('history'));
    expect(tester.takeException(), isNull);
  });
}
