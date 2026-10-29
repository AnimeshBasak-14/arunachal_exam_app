import 'package:arunachal_exam_app/core/services/question_repository.dart';
import 'package:arunachal_exam_app/core/theme/app_theme.dart';
import 'package:arunachal_exam_app/features/exam/data/attempt.dart';
import 'package:arunachal_exam_app/features/exam/view/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_app.dart';

Question _q(String id, String subject, String correct) {
  return Question(
    id: id,
    examCode: 'APSSB-CGL',
    year: 2024,
    subject: subject,
    topic: subject,
    questionText: 'Question $id',
    options: const ['Opt A', 'Opt B', 'Opt C', 'Opt D'],
    correctAnswer: correct.toLowerCase(),
    officialAnswer: correct.toLowerCase(),
    solution: 'Solution $id',
  );
}

Attempt _buildAttempt({
  required String examCode,
  required double score,
  required double maxScore,
  required String date,
  int correct = 5,
  int wrong = 5,
  int left = 0,
  int ungraded = 0,
  String mode = 'exam',
  List<Question>? questions,
  Map<String, String>? selected,
}) {
  return Attempt(
    title: 'APSSB CGL 2024',
    examCode: examCode,
    mode: mode,
    score: score,
    maxScore: maxScore,
    correct: correct,
    wrong: wrong,
    left: left,
    ungraded: ungraded,
    timeTaken: 1200,
    date: date,
    ratingChange: 0,
    speedBonus: 0,
    selected: selected ?? const {},
    questions: questions ?? const [],
    raw: const {},
  );
}

void main() {
  Widget buildApp(Widget child, {bool dark = false}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: child,
      ),
    );
  }

  testWidgets('ResultScreen with 0 previous attempts (first attempt)', (tester) async {
    phoneViewport(tester);
    final prefs = await testPrefs();
    final current = _buildAttempt(
      examCode: 'APSSB-CGL',
      score: 50,
      maxScore: 100,
      date: '2026-10-29T10:00:00Z',
    );

    await tester.pumpWidget(ProviderScope(
      overrides: testOverrides(prefs),
      child: buildApp(ResultScreen(attempt: current, history: [current])),
    ));
    await settle(tester, 5);

    expect(find.text('50%'), findsAtLeastNWidgets(1));
    expect(find.text('50'), findsOneWidget);
    expect(find.text('/ 100'), findsOneWidget);
    expect(find.text('First attempt. This is your starting point.'), findsOneWidget);
    expect(find.text('New personal best'), findsNothing);
    expect(find.text('Review mistakes'), findsNothing); // qs is empty
    expect(tester.takeException(), isNull);
  });

  testWidgets('ResultScreen with 1 previous attempt (improvement and personal best)', (tester) async {
    phoneViewport(tester);
    final prefs = await testPrefs();
    final prev = _buildAttempt(
      examCode: 'APSSB-CGL',
      score: 40,
      maxScore: 100,
      date: '2026-10-27T10:00:00Z',
    );
    final current = _buildAttempt(
      examCode: 'APSSB-CGL',
      score: 75,
      maxScore: 100,
      date: '2026-10-29T10:00:00Z',
    );

    await tester.pumpWidget(ProviderScope(
      overrides: testOverrides(prefs),
      child: buildApp(ResultScreen(attempt: current, history: [current, prev])),
    ));
    await settle(tester, 5);

    expect(find.text('75%'), findsOneWidget);
    expect(find.text('+35 points since your last APSSB-CGL attempt'), findsOneWidget);
    expect(find.text('New personal best'), findsOneWidget);
    expect(find.text('Last 2 attempts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ResultScreen with 3 previous attempts in dark mode at 130% text (drop & weak topic)', (tester) async {
    phoneViewport(tester);
    final prefs = await testPrefs();
    final a1 = _buildAttempt(
      examCode: 'APSSB-CGL',
      score: 60,
      maxScore: 100,
      date: '2026-10-23T10:00:00Z',
    );
    final a2 = _buildAttempt(
      examCode: 'APSSB-CGL',
      score: 85,
      maxScore: 100,
      date: '2026-10-25T10:00:00Z',
    );
    final a3 = _buildAttempt(
      examCode: 'APSSB-CGL',
      score: 80,
      maxScore: 100,
      date: '2026-10-27T10:00:00Z',
    );

    // Current attempt has questions with low accuracy in Polity
    final questions = [
      _q('q1', 'Polity', 'a'),
      _q('q2', 'Polity', 'a'),
      _q('q3', 'Polity', 'a'),
      _q('q4', 'History', 'a'),
      _q('q5', 'History', 'b'),
      _q('q6', 'History', 'c'),
    ];
    final selected = {
      'q1': 'b', // wrong
      'q2': 'b', // wrong
      'q3': 'a', // correct (33% accuracy in Polity)
      'q4': 'a', // correct
      'q5': 'b', // correct
      'q6': 'c', // correct (100% in History)
    };

    final current = _buildAttempt(
      examCode: 'APSSB-CGL',
      score: 55,
      maxScore: 100,
      date: '2026-10-29T10:00:00Z',
      questions: questions,
      selected: selected,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: testOverrides(prefs),
      child: buildApp(
        ResultScreen(attempt: current, history: [current, a3, a2, a1]),
        dark: true,
      ),
    ));
    await settle(tester, 5);

    expect(find.text('55%'), findsOneWidget);
    expect(find.text('-25 points since your last APSSB-CGL attempt'), findsOneWidget);
    expect(find.text('A dip is normal. Review the questions you missed.'), findsOneWidget);
    expect(find.text('Last 4 attempts'), findsOneWidget);
    expect(find.text('Practise your weak topics (Polity)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
