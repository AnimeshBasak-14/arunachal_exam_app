import 'dart:convert';
import 'package:arunachal_exam_app/core/services/question_repository.dart';
import 'package:arunachal_exam_app/core/services/study_reminder_service.dart';
import 'package:arunachal_exam_app/core/theme/app_theme.dart';
import 'package:arunachal_exam_app/features/exam/data/attempt.dart';
import 'package:arunachal_exam_app/features/plan/data/study_plan.dart';
import 'package:arunachal_exam_app/features/plan/view/study_plan_sheet.dart';
import 'package:arunachal_exam_app/features/shell/view/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_app.dart';

class _FakeReminderService implements StudyReminderService {
  bool granted = true;
  @override
  Future<bool> hasPermission() async => granted;
  @override
  Future<bool> requestPermission() async => granted;
  @override
  Future<bool> scheduleDailyReminder({required int hour, required int minute, required int cardGoal}) async => true;
  @override
  Future<bool> cancelDailyReminder() async => true;
}

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

void main() {
  testWidgets('StudyPlanSheet Step 1 and Step 2 flow', (tester) async {
    phoneViewport(tester);
    final prefs = await testPrefs({'exam_goal_id': 'apssb-cgl'});
    final fakeReminder = _FakeReminderService();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...testOverrides(prefs),
        studyReminderServiceProvider.overrideWithValue(fakeReminder),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => showStudyPlanSheet(context, isFirstRun: true),
              child: const Text('Open Sheet'),
            );
          }),
        ),
      ),
    ));

    await tester.tap(find.text('Open Sheet'));
    await settle(tester, 5);

    // Step 1: When is your exam?
    expect(find.text('When is your exam?'), findsOneWidget);
    expect(find.text("I don't know yet"), findsOneWidget);
    expect(find.text('Choose your exam date'), findsOneWidget);

    // Advance to Step 2 via "I don't know yet"
    await tester.tap(find.text("I don't know yet"));
    await settle(tester, 5);

    // Step 2: When will you study?
    expect(find.text('When will you study?'), findsOneWidget);
    expect(find.text('Daily card target'), findsOneWidget);
    expect(find.text('Daily question target'), findsOneWidget);
    expect(find.textContaining('20 cards'), findsOneWidget);
    expect(find.text('Save & start preparing'), findsOneWidget);

    await tester.tap(find.text('Save & start preparing'));
    await settle(tester, 5);

    expect(find.text('When will you study?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard shows the PYQ of the day and no old streak card', (tester) async {
    phoneViewport(tester);
    final prefs = await testPrefs({'exam_goal_id': 'apssb-cgl'});
    final fakeReminder = _FakeReminderService();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...testOverrides(prefs),
        studyReminderServiceProvider.overrideWithValue(fakeReminder),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: scaled(const AppShell(initialTab: 0)),
      ),
    ));
    await settle(tester);

    expect(find.text('PYQ OF THE DAY'), findsOneWidget);
    expect(find.text('TODAY'), findsNothing);
    expect(find.text('Start your streak'), findsNothing);
    expect(find.text('Previous Year Papers'), findsNothing);
    expect(find.textContaining('days to your exam'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard header shows the real exam countdown', (tester) async {
    phoneViewport(tester);
    final future = DateTime.now().add(const Duration(days: 47));
    final plan = StudyPlan(
      examDate: future,
      dailyGoal: 20,
      completed: true,
    );
    final prefs = await testPrefs({
      'exam_goal_id': 'apssb-cgl',
      'study_plan_v1': jsonEncode(plan.toJson()),
    });
    final fakeReminder = _FakeReminderService();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...testOverrides(prefs),
        studyReminderServiceProvider.overrideWithValue(fakeReminder),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: scaled(const AppShell(initialTab: 0)),
      ),
    ));
    await settle(tester);

    // 47 days out is more than a month, so the timer shows months and days.
    expect(find.text('TIME TO YOUR EXAM'), findsOneWidget);
    expect(find.textContaining('MONTH'), findsOneWidget);
    expect(find.text('DAYS'), findsOneWidget);
    expect(find.text('PYQ OF THE DAY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Weak topics are not on the dashboard any more', (tester) async {
    phoneViewport(tester);
    final q1 = _q('q1', 'Polity', 'a');
    final q2 = _q('q2', 'Polity', 'a');
    final q3 = _q('q3', 'Polity', 'a');
    final attemptJson = {
      'testTitle': 'APSSB CGL 2024',
      'examCode': 'APSSB-CGL',
      'mode': 'exam',
      'score': 1.0,
      'maxScore': 3.0,
      'correct': 1,
      'wrong': 2,
      'date': '2026-10-29T10:00:00Z',
      'selectedAnswers': {'q1': 'b', 'q2': 'b', 'q3': 'a'},
      'questions': [
        Attempt.questionToMap(q1),
        Attempt.questionToMap(q2),
        Attempt.questionToMap(q3),
      ],
    };

    final prefs = await testPrefs({
      'exam_goal_id': 'apssb-cgl',
      'quiz_history': [jsonEncode(attemptJson)],
    });
    final fakeReminder = _FakeReminderService();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...testOverrides(prefs),
        studyReminderServiceProvider.overrideWithValue(fakeReminder),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: scaled(const AppShell(initialTab: 0)),
      ),
    ));
    await settle(tester);

    expect(find.text('Polity is your weakest area (33%).'), findsNothing);
    expect(find.text('Practise Polity'), findsNothing);
    expect(find.text('PYQ OF THE DAY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
