import 'package:flutter_test/flutter_test.dart';
import 'package:arunachal_exam_app/core/services/study_reminder_service.dart';
import 'package:arunachal_exam_app/features/plan/data/study_plan.dart';
import 'package:arunachal_exam_app/features/plan/data/study_plan_provider.dart';
import '../helpers/test_app.dart';

class FakeStudyReminderService implements StudyReminderService {
  int? scheduledHour;
  int? scheduledMinute;
  int? scheduledGoal;
  bool wasCancelled = false;
  bool permissionGranted = true;

  @override
  Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    required int cardGoal,
  }) async {
    scheduledHour = hour;
    scheduledMinute = minute;
    scheduledGoal = cardGoal;
    wasCancelled = false;
    return true;
  }

  @override
  Future<void> cancelDailyReminder() async {
    wasCancelled = true;
    scheduledHour = null;
    scheduledMinute = null;
    scheduledGoal = null;
  }

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;
}

void main() {
  group('StudyPlan daysUntilExam', () {
    final today = DateTime(2026, 10, 29);

    test('returns null when no examDate is set', () {
      const plan = StudyPlan();
      expect(plan.daysUntilExam(today), isNull);
      expect(plan.deadlineLabel(today), isNull);
    });

    test('returns 0 and "Exam day is today" when exam is today', () {
      final plan = StudyPlan(examDate: DateTime(2026, 10, 29));
      expect(plan.daysUntilExam(today), 0);
      expect(plan.deadlineLabel(today), 'Exam day is today');
    });

    test('returns 1 and "1 day to your exam" for tomorrow', () {
      final plan = StudyPlan(examDate: DateTime(2026, 10, 30));
      expect(plan.daysUntilExam(today), 1);
      expect(plan.deadlineLabel(today), '1 day to your exam');
    });

    test('returns positive count for future dates across month/year boundaries',
        () {
      final planNextMonth = StudyPlan(examDate: DateTime(2026, 11, 15));
      expect(planNextMonth.daysUntilExam(today), 17);
      expect(planNextMonth.deadlineLabel(today), '17 days to your exam');

      final planNextYear = StudyPlan(examDate: DateTime(2027, 1, 1));
      expect(planNextYear.daysUntilExam(today), 64);
    });

    test('returns negative count when exam date is in the past', () {
      final past = StudyPlan(examDate: DateTime(2026, 10, 10));
      expect(past.daysUntilExam(today), -19);
      expect(past.deadlineLabel(today), isNull);
    });
  });

  group('StudyPlan serialization round-trip', () {
    test('round trips complete plan to JSON and back', () {
      final plan = StudyPlan(
        examDate: DateTime(2026, 12, 1),
        reminderHour: 20,
        reminderMinute: 30,
        remindersEnabled: true,
        dailyGoal: 30,
        completed: true,
      );

      final json = plan.toJson();
      final restored = StudyPlan.fromJson(json);

      expect(restored.examDate, DateTime(2026, 12, 1));
      expect(restored.reminderHour, 20);
      expect(restored.reminderMinute, 30);
      expect(restored.reminderTimeString, '8:30 PM');
      expect(restored.remindersEnabled, isTrue);
      expect(restored.dailyGoal, 30);
      expect(restored.completed, isTrue);
    });
  });

  group('StudyPlanNotifier with SharedPreferences & ReminderService', () {
    test('saves plan and schedules reminder on fake service', () async {
      final prefs = await testPrefs();
      final fakeReminder = FakeStudyReminderService();

      final container = createContainer(
        overrides: [
          ...testOverrides(prefs),
          studyReminderServiceProvider.overrideWithValue(fakeReminder),
        ],
      );

      final notifier = container.read(studyPlanProvider.notifier);

      // Initial state
      expect(container.read(studyPlanProvider).completed, isFalse);
      expect(container.read(dailyCardGoalProvider), 20);

      // Complete setup with reminder at 8 PM and 30 cards
      await notifier.completeSetup(
        examDate: DateTime(2026, 11, 20),
        remindersEnabled: true,
        reminderHour: 20,
        reminderMinute: 0,
        dailyGoal: 30,
      );

      final state = container.read(studyPlanProvider);
      expect(state.completed, isTrue);
      expect(state.dailyGoal, 30);
      expect(state.remindersEnabled, isTrue);
      expect(container.read(dailyCardGoalProvider), 30);

      // Verify fake notification scheduled
      expect(fakeReminder.scheduledHour, 20);
      expect(fakeReminder.scheduledGoal, 30);
      expect(fakeReminder.wasCancelled, isFalse);

      // Turn reminder off
      await notifier.cancelReminders();
      expect(container.read(studyPlanProvider).remindersEnabled, isFalse);
      expect(fakeReminder.wasCancelled, isTrue);
    });
  });
}
