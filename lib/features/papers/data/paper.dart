import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/exam_goals.dart';
import '../../../core/services/exam_repository.dart';
import '../../../core/services/service_providers.dart';

enum PaperKind { pyq, mock }

/// A previous-year paper or mock test row from the `tests` table.
/// Fields are nullable so missing data is shown as missing, never guessed.
class Paper {
  final String id;
  final PaperKind kind;
  final String title;
  final String examCode;
  final Department department;
  final int? year;
  final String? shift;
  final String? subject;
  final String? difficulty;
  final int questionCount;
  final int? officialQuestionCount;
  final int? durationMinutes;
  final double? marksPerCorrect;
  final double? negativeMarks;

  const Paper({
    required this.id,
    required this.kind,
    required this.title,
    required this.examCode,
    required this.department,
    required this.questionCount,
    this.year,
    this.shift,
    this.subject,
    this.difficulty,
    this.officialQuestionCount,
    this.durationMinutes,
    this.marksPerCorrect,
    this.negativeMarks,
  });

  bool get isIncomplete =>
      officialQuestionCount != null &&
      officialQuestionCount! > 0 &&
      questionCount < officialQuestionCount!;

  /// Exam code without the board prefix and year suffix, e.g. "CGLE".
  String get shortCode {
    final cleaned = examCode
        .replaceAll(RegExp(r'^(APPSC|APSSB)[-_ ]?', caseSensitive: false), '')
        .replaceAll(RegExp(r'[-_ ]?(19|20)\d\d$'), '');
    return cleaned.isEmpty ? examCode : cleaned;
  }

  /// Timer used for exam mode. Papers without an official duration get one
  /// minute per question (minimum 10).
  int get effectiveDuration => durationMinutes ?? math.max(10, questionCount);

  String get shiftLabel {
    final s = shift?.trim() ?? '';
    if (s.isEmpty) return '';
    return s.toLowerCase().startsWith('shift') ? s : 'Shift $s';
  }

  static int? _int(dynamic v) => v == null ? null : int.tryParse(v.toString());
  static double? _double(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());
  static String? _str(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  factory Paper.fromSupabase(Map<String, dynamic> data, PaperKind kind) {
    final examCode = (_str(data['exam_code']) ?? '').toUpperCase();
    int count = 0;
    final q = data['questions'];
    if (q is List && q.isNotEmpty && q.first is Map) {
      count = _int((q.first as Map)['count']) ?? 0;
    }
    final official = _int(data['total_questions']);
    return Paper(
      id: data['id']?.toString() ?? '',
      kind: kind,
      title: _str(data['title']) ??
          (examCode.isEmpty ? 'Untitled paper' : examCode),
      examCode: examCode,
      department: Department.classify(examCode,
          board: _str(data['board']) ?? _str(data['agency_code'])),
      year: _int(data['year']),
      shift: _str(data['shift']) ?? _str(data['session']),
      subject: _str(data['subject']),
      difficulty: _str(data['difficulty']),
      questionCount: count > 0 ? count : 0,
      officialQuestionCount: official,
      durationMinutes: _int(data['duration_minutes']),
      marksPerCorrect: _double(data['marks_per_correct']),
      negativeMarks: _double(data['negative_marks']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'exam_code': examCode,
        'year': year,
        'shift': shift,
        'subject': subject,
        'difficulty': difficulty,
        'question_count': questionCount,
        'total_questions': officialQuestionCount,
        'duration_minutes': durationMinutes,
        'marks_per_correct': marksPerCorrect,
        'negative_marks': negativeMarks,
      };

  factory Paper.fromJson(Map<String, dynamic> j) {
    final code = j['exam_code']?.toString() ?? '';
    return Paper(
      id: j['id']?.toString() ?? '',
      kind: j['kind'] == 'mock' ? PaperKind.mock : PaperKind.pyq,
      title: j['title']?.toString() ?? code,
      examCode: code,
      department: Department.classify(code),
      year: _int(j['year']),
      shift: _str(j['shift']),
      subject: _str(j['subject']),
      difficulty: _str(j['difficulty']),
      questionCount: _int(j['question_count']) ?? 0,
      officialQuestionCount: _int(j['total_questions']),
      durationMinutes: _int(j['duration_minutes']),
      marksPerCorrect: _double(j['marks_per_correct']),
      negativeMarks: _double(j['negative_marks']),
    );
  }

  /// Route into the exam engine. Study mode shows answers as you go.
  String examRoute({required bool study}) {
    final type = kind == PaperKind.pyq ? 'PYQ' : 'MOCK';
    final code = Uri.encodeComponent(examCode.isEmpty ? 'ALL' : examCode);
    final params = <String, String>{
      'paperType': type,
      'testId': id,
      'title': title,
      if (year != null) 'year': '$year',
      if (study) 'study': 'true' else 'duration': '$effectiveDuration',
    };
    return Uri(path: '/mock-test/$code/full', queryParameters: params)
        .toString();
  }
}

class PapersResult {
  final List<Paper> papers;
  final bool isOffline;
  const PapersResult(this.papers, {this.isOffline = false});

  List<Paper> byDepartment(Department? d) =>
      d == null ? papers : papers.where((p) => p.department == d).toList();
}

/// Papers with at least one question, newest first. Falls back to the last
/// list saved on the device when the network is unavailable.
final papersProvider =
    FutureProvider.family<PapersResult, PaperKind>((ref, kind) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final cacheKey = 'cached_papers_${kind.name}_v3';
  final type = kind == PaperKind.pyq ? 'PYQ' : 'MOCK';

  try {
    final raw = await ExamRepository.instance
        .fetchPapers(paperType: type, forceRefresh: true);
    if (raw.isNotEmpty) {
      final papers = raw
          .map((d) => Paper.fromSupabase(d, kind))
          .where((p) => p.questionCount > 0)
          .toList();
      await prefs.setString(
          cacheKey, jsonEncode(papers.map((p) => p.toJson()).toList()));
      return PapersResult(papers);
    }
  } catch (e) {
    debugPrint('[papersProvider] $e');
  }

  final cached = prefs.getString(cacheKey);
  if (cached != null && cached.isNotEmpty) {
    try {
      final list = (jsonDecode(cached) as List)
          .map((e) => Paper.fromJson(e as Map<String, dynamic>))
          .where((p) => p.questionCount > 0)
          .toList();
      return PapersResult(list, isOffline: true);
    } catch (_) {}
  }
  return const PapersResult([], isOffline: true);
});
