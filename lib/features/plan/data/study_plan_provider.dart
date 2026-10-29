import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/study_reminder_service.dart';
import 'study_plan.dart';

class StudyPlanNotifier extends Notifier<StudyPlan> {
  static const _prefKey = 'study_plan_v1';
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  StudyReminderService get _reminder => ref.read(studyReminderServiceProvider);

  @override
  StudyPlan build() {
    final raw = _prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) {
      return const StudyPlan();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StudyPlan.fromJson(map);
    } catch (_) {
      return const StudyPlan();
    }
  }

  Future<void> _save(StudyPlan updated) async {
    state = updated;
    await _prefs.setString(_prefKey, jsonEncode(updated.toJson()));
    if (updated.remindersEnabled) {
      await _reminder.scheduleDailyReminder(
        hour: updated.reminderHour,
        minute: updated.reminderMinute,
        cardGoal: updated.dailyGoal,
      );
    } else {
      await _reminder.cancelDailyReminder();
    }
  }

  Future<void> setExamDate(DateTime? date) async {
    final updated = date == null
        ? state.copyWith(clearExamDate: true)
        : state.copyWith(examDate: date);
    await _save(updated);
  }

  Future<void> setDailyGoal(int goal) async {
    final validGoal = (goal == 10 || goal == 20 || goal == 30) ? goal : 20;
    await _save(state.copyWith(dailyGoal: validGoal));
  }

  Future<bool> setReminder({
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    if (enabled) {
      final granted = await _reminder.requestPermission();
      if (!granted) {
        await _save(state.copyWith(
          reminderHour: hour ?? state.reminderHour,
          reminderMinute: minute ?? state.reminderMinute,
          remindersEnabled: false,
        ));
        return false;
      }
    }
    await _save(state.copyWith(
      reminderHour: hour ?? state.reminderHour,
      reminderMinute: minute ?? state.reminderMinute,
      remindersEnabled: enabled,
    ));
    return enabled;
  }

  Future<void> completeSetup({
    DateTime? examDate,
    bool remindersEnabled = false,
    int? reminderHour,
    int? reminderMinute,
    int dailyGoal = 20,
  }) async {
    if (remindersEnabled) {
      final granted = await _reminder.requestPermission();
      remindersEnabled = granted;
    }
    final updated = StudyPlan(
      examDate: examDate,
      reminderHour: reminderHour ?? 19,
      reminderMinute: reminderMinute ?? 0,
      remindersEnabled: remindersEnabled,
      dailyGoal: dailyGoal,
      completed: true,
    );
    await _save(updated);
  }

  Future<void> skipSetup() async {
    final updated = state.copyWith(completed: true);
    await _save(updated);
  }

  Future<void> cancelReminders() async {
    await _save(state.copyWith(remindersEnabled: false));
  }
}

final studyPlanProvider =
    NotifierProvider<StudyPlanNotifier, StudyPlan>(StudyPlanNotifier.new);

/// Dynamically provides the active daily card goal from the student's study plan.
final dailyCardGoalProvider = Provider<int>((ref) {
  return ref.watch(studyPlanProvider).dailyGoal;
});
