import 'dart:convert';
import '../../../core/services/question_repository.dart';
import '../../../core/services/storage_service.dart';

/// One finished test, stored in quiz history as JSON.
///
/// Field names match the records written by earlier app versions, so old
/// history still opens in the new result and analytics screens.
class Attempt {
  final String title;
  final String examCode;
  final String mode; // 'exam' or 'study'
  final double score;
  final double maxScore;
  final int correct;
  final int wrong;
  final int left;
  final int ungraded;
  final int timeTaken; // seconds
  final String date;
  final int ratingChange;
  final int speedBonus;
  final int? newRating;
  final Map<String, String> selected;
  final List<Question> questions;
  final Map<String, dynamic> raw;

  const Attempt({
    required this.title,
    required this.examCode,
    required this.mode,
    required this.score,
    required this.maxScore,
    required this.correct,
    required this.wrong,
    required this.left,
    required this.ungraded,
    required this.timeTaken,
    required this.date,
    required this.ratingChange,
    required this.speedBonus,
    required this.selected,
    required this.questions,
    required this.raw,
    this.newRating,
  });

  int get attempted => correct + wrong;
  double get accuracy => attempted == 0 ? 0 : correct / attempted;
  double get scoreRatio => maxScore <= 0 ? 0 : (score / maxScore).clamp(0, 1);

  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
  static int _i(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  factory Attempt.fromJson(Map<String, dynamic> j) {
    final sel = <String, String>{};
    final rawSel = j['selectedAnswers'];
    if (rawSel is Map) {
      rawSel.forEach((k, v) => sel[k.toString()] = v.toString());
    }
    final qs = <Question>[];
    final rawQs = j['questions'];
    if (rawQs is List) {
      for (final m in rawQs.whereType<Map>()) {
        final map = Map<String, dynamic>.from(m);
        qs.add(Question.fromMap(map['id']?.toString() ?? '', map));
      }
    }
    final examCode = j['examCode']?.toString() ?? '';
    final title = j['testTitle']?.toString() ?? '';
    return Attempt(
      title: title.isNotEmpty ? title : (examCode.isEmpty ? 'Practice test' : examCode),
      examCode: examCode,
      mode: j['mode']?.toString() ?? 'exam',
      score: _d(j['score']),
      maxScore: _d(j['maxScore']),
      correct: _i(j['correct']),
      wrong: _i(j['wrong']),
      left: _i(j['left']),
      ungraded: _i(j['ungraded']),
      timeTaken: _i(j['timeTaken']),
      date: (j['date'] ?? j['completedAt'] ?? '').toString(),
      ratingChange: _i(j['ratingChange']),
      speedBonus: _i(j['speedBonus']),
      newRating: j['newRating'] == null ? null : _i(j['newRating']),
      selected: sel,
      questions: qs,
      raw: j,
    );
  }

  /// Question in the shape [Question.fromMap] reads back.
  static Map<String, dynamic> questionToMap(Question q) => {
        'id': q.id,
        'questionText': q.questionText,
        'subject': q.subject,
        'topic': q.topic,
        'examCode': q.examCode,
        'options': q.options,
        'correctAnswer': q.correctAnswer,
        'officialAnswer': q.officialAnswer,
        'solution': q.solution,
        'difficulty': q.difficulty,
        'year': q.year,
        'passageOrDirection': q.passageOrDirection,
        'passageImage': q.passageImage,
        'directionText': q.directionText,
        'questionImage': q.questionImage,
        'marksPerCorrect': q.marksPerCorrect,
        'negativeMarks': q.negativeMarks,
      };
}

/// Newest first; unreadable records are skipped.
List<Attempt> loadAttempts(StorageService storage) {
  final out = <Attempt>[];
  for (final s in storage.getQuizHistory()) {
    try {
      out.add(Attempt.fromJson(jsonDecode(s) as Map<String, dynamic>));
    } catch (_) {}
  }
  return out;
}
