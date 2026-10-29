import 'dart:math' as math;
import '../../learn/data/topic_mapping.dart';
import 'attempt.dart';

/// The comparative analysis between the current attempt and the student's own history.
class ResultComparison {
  final Attempt current;
  final Attempt? previous;
  final bool isFirstAttempt;
  final bool isPersonalBest;
  final int? deltaPoints; // e.g. +12, -5, 0 (percentage points)
  final List<Attempt> recentAttempts; // Up to 5 attempts for this exam & mode, chronological
  final WeakTopicSuggestion? weakTopic;

  const ResultComparison({
    required this.current,
    required this.previous,
    required this.isFirstAttempt,
    required this.isPersonalBest,
    required this.deltaPoints,
    required this.recentAttempts,
    required this.weakTopic,
  });

  /// The headline message comparing against the last attempt, or first-attempt notice.
  String get deltaHeadline {
    if (isFirstAttempt || previous == null || deltaPoints == null) {
      return 'First attempt. This is your starting point.';
    }
    final code = current.examCode.trim().isNotEmpty ? current.examCode.trim() : 'similar';
    if (deltaPoints! > 0) {
      return '+$deltaPoints points since your last $code attempt';
    }
    if (deltaPoints! < 0) {
      return '$deltaPoints points since your last $code attempt';
    }
    return 'Same as last time';
  }

  /// Calm supporting sub-copy when score drops.
  String? get deltaSubline {
    if (deltaPoints != null && deltaPoints! < 0) {
      return 'A dip is normal. Review the questions you missed.';
    }
    return null;
  }
}

/// Pure comparison function.
///
/// Evaluates [current] against [history] (which may or may not already include [current]).
ResultComparison compare(Attempt current, List<Attempt> history) {
  // Exclude [current] itself if already persisted in history.
  var earlier = <Attempt>[];
  bool skippedSelf = false;
  for (final a in history) {
    if (!skippedSelf && (identical(a, current) || _isSameAttempt(a, current))) {
      skippedSelf = true;
      continue;
    }
    earlier.add(a);
  }

  // Filter for comparable attempts: same examCode, same mode, gradable (maxScore > 0).
  final comparable = earlier
      .where((a) =>
          a.examCode == current.examCode &&
          a.mode == current.mode &&
          a.maxScore > 0)
      .toList();

  final Attempt? previous = comparable.isEmpty ? null : comparable.first;
  final bool isFirst = previous == null;

  // Personal best: checks any earlier attempt for that examCode with maxScore > 0.
  // Applies only if there was at least one earlier attempt to beat.
  final earlierForExam = earlier
      .where((a) => a.examCode == current.examCode && a.maxScore > 0)
      .toList();

  final bool isPersonalBest = !isFirst &&
      earlierForExam.isNotEmpty &&
      current.scoreRatio >
          earlierForExam.map((a) => a.scoreRatio).reduce(math.max);

  int? delta;
  if (previous != null) {
    final curPct = (current.scoreRatio * 100).round();
    final prevPct = (previous.scoreRatio * 100).round();
    delta = curPct - prevPct;
  }

  // Up to 5 attempts for that examCode & mode, ordered chronologically (oldest -> newest).
  final List<Attempt> recent = [
    ...comparable.take(4).toList().reversed,
    current,
  ];

  final weakTopic = findWeakTopicForAttempt(current);

  return ResultComparison(
    current: current,
    previous: previous,
    isFirstAttempt: isFirst,
    isPersonalBest: isPersonalBest,
    deltaPoints: delta,
    recentAttempts: recent,
    weakTopic: weakTopic,
  );
}

bool _isSameAttempt(Attempt a, Attempt b) {
  return a.date == b.date &&
      a.title == b.title &&
      a.examCode == b.examCode &&
      a.score == b.score &&
      a.maxScore == b.maxScore &&
      a.timeTaken == b.timeTaken;
}
