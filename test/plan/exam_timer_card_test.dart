import 'dart:convert';
import 'package:arunachal_exam_app/core/services/study_reminder_service.dart';
import 'package:arunachal_exam_app/core/theme/app_theme.dart';
import 'package:arunachal_exam_app/features/dashboard/view/exam_timer_card.dart';
import 'package:arunachal_exam_app/features/plan/data/study_plan.dart';
import 'package:arunachal_exam_app/features/plan/data/study_plan_provider.dart';
import 'package:arunachal_exam_app/features/streak/data/day_key.dart';
import 'package:arunachal_exam_app/features/streak/data/questions_today.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_app.dart';

class _Reminder implements StudyReminderService {
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> scheduleDailyReminder(
          {required int hour,
          required int minute,
          required int cardGoal}) async =>
      true;
  @override
  Future<bool> cancelDailyReminder() async => true;
}

Future<void> pumpCard(
  WidgetTester tester, {
  StudyPlan? plan,
  int answered = 0,
}) async {
  phoneViewport(tester);
  final prefs = await testPrefs({
    if (plan != null) 'study_plan_v1': jsonEncode(plan.toJson()),
    if (answered > 0) ...{
      'questions_today_count': answered,
      'questions_today_day': dayKey(DateTime.now()),
    },
  });
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ...testOverrides(prefs),
      studyReminderServiceProvider.overrideWithValue(_Reminder()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: scaled(const Scaffold(
          body: Padding(padding: EdgeInsets.all(20), child: ExamTimerCard()))),
    ),
  ));
  await settle(tester, 3);
}

DateTime inDays(int d, {int hours = 0}) =>
    DateTime.now().add(Duration(days: d, hours: hours));

void main() {
  testWidgets('no exam date asks for one and still shows the question ring',
      (tester) async {
    await pumpCard(tester);
    expect(find.text('Add your exam date'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('of 10'), findsOneWidget);
    expect(find.text('Practise'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('over a month away shows months and days', (tester) async {
    await pumpCard(tester,
        plan: StudyPlan(examDate: inDays(75), completed: true));
    expect(find.text('TIME TO YOUR EXAM'), findsOneWidget);
    expect(find.textContaining('MONTH'), findsOneWidget);
    expect(find.textContaining('DAY'), findsOneWidget);
    expect(find.text('HRS'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('under a month shows days and hours', (tester) async {
    await pumpCard(tester,
        plan: StudyPlan(examDate: inDays(12), completed: true));
    expect(find.text('DAYS'), findsOneWidget);
    expect(find.text('HRS'), findsOneWidget);
    expect(find.text('MIN'), findsNothing);
    expect(find.textContaining('MONTH'), findsNothing);
  });

  testWidgets('under a week adds minutes', (tester) async {
    await pumpCard(tester,
        plan: StudyPlan(examDate: inDays(5), completed: true));
    expect(find.text('HRS'), findsOneWidget);
    expect(find.text('MIN'), findsOneWidget);
    expect(find.text('SEC'), findsNothing);
  });

  testWidgets('under three days adds seconds and keeps refreshing cleanly',
      (tester) async {
    await pumpCard(tester,
        plan: StudyPlan(examDate: inDays(1, hours: 5), completed: true));
    expect(find.text('SEC'), findsOneWidget);
    // The card refreshes every second here (see examCountdown's
    // ticksEverySecond); it must do so without errors and stop on dispose.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('SEC'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('a past date asks for the next one', (tester) async {
    await pumpCard(tester,
        plan: StudyPlan(examDate: inDays(-3), completed: true));
    expect(find.text('Your exam date has passed'), findsOneWidget);
    expect(find.text('SEC'), findsNothing);
  });

  testWidgets('the ring follows the plan target and todays answers',
      (tester) async {
    await pumpCard(tester,
        plan: const StudyPlan(dailyQuestions: 20, completed: true),
        answered: 7);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('of 20'), findsOneWidget);
    expect(find.textContaining('13 more questions'), findsOneWidget);
  });

  testWidgets('reaching the target is acknowledged', (tester) async {
    await pumpCard(tester,
        plan: const StudyPlan(dailyQuestions: 5, completed: true), answered: 6);
    expect(find.text('Question target reached today'), findsOneWidget);
    expect(find.text('Keep going'), findsOneWidget);
  });

  group('questions today and the plan target', () {
    test('counter adds, persists and resets on a new day', () async {
      SharedPreferences.setMockInitialValues({
        'questions_today_count': 9,
        'questions_today_day': '2020-01-01',
      });
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [
        ...testOverrides(prefs),
      ]);
      addTearDown(c.dispose);
      expect(c.read(questionsTodayProvider),
          0); // stored count is from another day
      c.read(questionsTodayProvider.notifier).add(3);
      c.read(questionsTodayProvider.notifier).add(2);
      c.read(questionsTodayProvider.notifier).add(0); // ignored
      expect(c.read(questionsTodayProvider), 5);
      expect(prefs.getInt('questions_today_count'), 5);
    });

    test('plan stores the question target and rejects odd values', () async {
      final prefs = await testPrefs();
      final c = ProviderContainer(overrides: [
        ...testOverrides(prefs),
        studyReminderServiceProvider.overrideWithValue(_Reminder()),
      ]);
      addTearDown(c.dispose);
      expect(c.read(dailyQuestionTargetProvider), 10);
      await c.read(studyPlanProvider.notifier).setDailyQuestions(30);
      expect(c.read(dailyQuestionTargetProvider), 30);
      await c.read(studyPlanProvider.notifier).setDailyQuestions(7);
      expect(c.read(dailyQuestionTargetProvider), 10);
    });

    test('old saved plans without the field get the default', () {
      final plan = StudyPlan.fromJson({'dailyGoal': 30, 'completed': true});
      expect(plan.dailyQuestions, 10);
      expect(
          StudyPlan.fromJson(const StudyPlan(dailyQuestions: 20).toJson())
              .dailyQuestions,
          20);
    });
  });
}
