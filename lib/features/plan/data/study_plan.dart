/// A student's self-set study plan and exam timeline.
///
/// Honest by design: the exam date is entered by the student (never hardcoded
/// or guessed). If the student has not set a date, no countdown is shown.
class StudyPlan {
  final DateTime? examDate;
  final int reminderHour; // 0..23 (default 19 = 7 PM)
  final int reminderMinute; // 0..59 (default 0)
  final bool remindersEnabled;
  final int dailyGoal; // 10, 20 or 30 cards (default 20)
  final bool completed; // true once completed or explicitly skipped

  const StudyPlan({
    this.examDate,
    this.reminderHour = 19,
    this.reminderMinute = 0,
    this.remindersEnabled = false,
    this.dailyGoal = 20,
    this.completed = false,
  });

  /// Computes whole calendar days from [fromDate] (defaults to today) to [examDate].
  ///
  /// Returns:
  /// - null if no [examDate] is set
  /// - 0 if the exam is today
  /// - > 0 if the exam is in the future
  /// - < 0 if the exam date has passed
  int? daysUntilExam([DateTime? fromDate]) {
    if (examDate == null) return null;
    final now = fromDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(examDate!.year, examDate!.month, examDate!.day);
    return target.difference(today).inDays;
  }

  /// Formatted deadline copy for the Today card.
  ///
  /// Returns null if no exam date is set.
  String? deadlineLabel([DateTime? fromDate]) {
    final days = daysUntilExam(fromDate);
    if (days == null) return null;
    if (days == 0) return 'Exam day is today';
    if (days == 1) return '1 day to your exam';
    if (days > 1) return '$days days to your exam';
    return null; // Passed dates are handled with "Set next exam date"
  }

  /// 12-hour formatted reminder time (e.g. "7:00 PM").
  String get reminderTimeString {
    final h = reminderHour % 12 == 0 ? 12 : reminderHour % 12;
    final m = reminderMinute.toString().padLeft(2, '0');
    final period = reminderHour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  StudyPlan copyWith({
    DateTime? examDate,
    bool clearExamDate = false,
    int? reminderHour,
    int? reminderMinute,
    bool? remindersEnabled,
    int? dailyGoal,
    bool? completed,
  }) {
    return StudyPlan(
      examDate: clearExamDate ? null : (examDate ?? this.examDate),
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'examDate': examDate?.toIso8601String(),
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'remindersEnabled': remindersEnabled,
        'dailyGoal': dailyGoal,
        'completed': completed,
      };

  factory StudyPlan.fromJson(Map<String, dynamic> j) {
    DateTime? parsedDate;
    if (j['examDate'] != null) {
      try {
        parsedDate = DateTime.parse(j['examDate'] as String);
      } catch (_) {}
    }
    return StudyPlan(
      examDate: parsedDate,
      reminderHour: (j['reminderHour'] as num?)?.toInt() ?? 19,
      reminderMinute: (j['reminderMinute'] as num?)?.toInt() ?? 0,
      remindersEnabled: j['remindersEnabled'] as bool? ?? false,
      dailyGoal: (j['dailyGoal'] as num?)?.toInt() ?? 20,
      completed: j['completed'] as bool? ?? false,
    );
  }
}
