import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:arunachal_exam_app/core/services/question_repository.dart';
import 'package:arunachal_exam_app/core/services/service_providers.dart';
import 'package:arunachal_exam_app/core/theme/app_theme.dart';
import 'package:arunachal_exam_app/features/exam/data/attempt.dart';
import 'package:arunachal_exam_app/features/exam/view/exam_screen.dart';
import 'package:arunachal_exam_app/features/exam/view/result_screen.dart';
import '../helpers/test_app.dart';

Question q(String id, String text, String key,
        {String subject = 'General Studies'}) =>
    Question(
      id: id,
      examCode: 'APSSB-CGLE',
      year: 2024,
      subject: subject,
      questionText: text,
      options: const ['(a) Itanagar', '(b) Tawang', '(c) Pasighat', '(d) Ziro'],
      correctAnswer: key,
      officialAnswer: key.isEmpty ? '' : '($key)',
      solution: 'Explanation for $id.',
    );

final questions = [
  q('q1', 'Capital of Arunachal Pradesh?', 'a'),
  q('q2', 'Oldest town of Arunachal Pradesh?', 'c'),
  q('q3', 'Question whose answer key is not verified yet?', ''),
];

Future<void> pumpExam(WidgetTester tester,
    {bool study = false, ThemeData? theme}) async {
  final prefs = await testPrefs();
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => ExamScreen(
        examCode: 'APSSB-CGLE',
        testType: 'full',
        title: 'Test paper',
        durationMinutes: 10,
        isStudyMode: study,
        initialQuestions: questions,
      ),
    ),
    GoRoute(
      path: '/mock-test-result',
      builder: (_, s) => ResultScreen(
          attempt: Attempt.fromJson(Map<String, dynamic>.from(s.extra as Map))),
    ),
    GoRoute(
        path: '/home', builder: (_, __) => const Scaffold(body: Text('HOME'))),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: testOverrides(prefs),
    child: MaterialApp.router(
      theme: theme ?? AppTheme.lightTheme,
      routerConfig: router,
      builder: (_, child) => scaled(child!),
    ),
  ));
  await settle(tester, 4);
}

void main() {
  testWidgets('exam flow: answer, review palette, submit, see the right score',
      (tester) async {
    phoneViewport(tester);
    await pumpExam(tester);

    expect(find.text('10:00'), findsOneWidget);
    expect(
        find.textContaining('Question 1', findRichText: true), findsOneWidget);
    expect(find.text('Capital of Arunachal Pradesh?'), findsOneWidget);

    await tester.tap(find.text('Itanagar')); // correct
    await tester.pump();
    await tester.tap(find.text('Next'));
    await settle(tester, 5);

    expect(find.text('Oldest town of Arunachal Pradesh?'), findsOneWidget);
    await tester.tap(find.text('Ziro').last); // wrong
    // 360px at 130% text: secondary actions are icon-only.
    await tester.tap(find.byTooltip('Mark for review'));
    await tester.pump();
    expect(find.byTooltip('Unmark review'), findsOneWidget);
    expect(find.byTooltip('Clear answer'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.square_grid_2x2));
    await settle(tester, 5);
    expect(find.text('Question palette'), findsOneWidget);
    expect(find.text('2 of 3 answered'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Submit test'));
    await settle(tester, 5);
    expect(find.text('Submit test?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await settle(tester, 8);

    // +2 for q1, -0.5 for q2, q3 is not graded: 1.5 out of 4.
    expect(find.text('1.5'), findsOneWidget);
    expect(find.text('/ 4'), findsOneWidget);
    expect(find.text('Review answers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('study mode reveals the key after answering and locks the answer',
      (tester) async {
    phoneViewport(tester);
    await pumpExam(tester, study: true);

    expect(find.text('Study mode'), findsOneWidget);
    await tester.tap(find.text('Tawang')); // wrong
    await settle(tester, 4);

    expect(find.text('ANSWER · A'), findsOneWidget);
    expect(find.text('Explanation for q1.'), findsOneWidget);

    await tester.tap(find.text('Itanagar')); // ignored: first answer is final
    await settle(tester, 2);
    expect(find.byIcon(CupertinoIcons.xmark), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history record is saved with questions and mode',
      (tester) async {
    phoneViewport(tester);
    await pumpExam(tester);
    await tester.tap(find.text('Itanagar'));
    await tester.pump();
    await tester.tap(find.byIcon(CupertinoIcons.square_grid_2x2));
    await settle(tester, 5);
    await tester.tap(find.text('Submit test'));
    await settle(tester, 5);
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await settle(tester, 8);

    final container =
        ProviderScope.containerOf(tester.element(find.byType(ResultScreen)));
    final prefs = container.read(sharedPreferencesProvider);
    final saved = prefs.getStringList('quiz_history')!;
    final record = jsonDecode(saved.first) as Map<String, dynamic>;
    expect(record['testTitle'], 'Test paper');
    expect(record['mode'], 'exam');
    expect(record['correct'], 1);
    expect(record['ungraded'], 1);
    expect((record['questions'] as List).length, 3);
  });

  testWidgets('dark theme renders the engine without overflow', (tester) async {
    phoneViewport(tester, size: const Size(320, 640));
    await pumpExam(tester, theme: AppTheme.darkTheme);
    await tester.tap(find.text('Pasighat'));
    await settle(tester, 3);
    expect(tester.takeException(), isNull);
  });
}
