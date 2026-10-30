import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/exam_goals.dart';
import '../../../core/services/service_providers.dart';
import '../../../data/official_syllabus_data.dart';

/// One paper (or subject) of an exam, with its syllabus split into topics a
/// student can tick off.
class SyllabusPaper {
  final String exam;
  final String stage;
  final String title;

  /// Short pattern facts: "25 questions", "50 marks", "2 hours".
  final List<String> facts;

  /// Marking rule, e.g. "No negative marking".
  final String marking;
  final List<String> topics;

  /// What this paper asks about Arunachal Pradesh, when stated.
  final String? arunachal;

  /// How the paper counts (screening, qualifying, merit), when stated.
  final String? weight;

  /// Physical, skill or interview stage rather than a written paper.
  final bool practical;

  const SyllabusPaper({
    required this.exam,
    required this.stage,
    required this.title,
    required this.facts,
    required this.marking,
    required this.topics,
    this.arunachal,
    this.weight,
    this.practical = false,
  });

  String get id => '$exam|$stage|$title';
  String topicKey(String topic) => '$id|$topic';
}

class SyllabusExam {
  final String name;
  final String board;
  final String cadres;
  final List<SyllabusPaper> papers;
  const SyllabusExam(this.name, this.board, this.cadres, this.papers);

  List<String> get stages => [
        for (final p in papers)
          if (!papers.takeWhile((q) => q != p).any((q) => q.stage == p.stage))
            p.stage
      ];

  Iterable<String> get topicKeys => [
        for (final p in papers)
          for (final t in p.topics) p.topicKey(t)
      ];
}

/// Splits a syllabus line into topics: on ";" when the board used them,
/// else on commas outside brackets. Prose (several sentences) stays whole.
List<String> splitTopics(String raw) {
  var t = raw.trim();
  final lead = RegExp(r'^[A-Z][A-Za-z ]{2,30}: ').firstMatch(t);
  if (lead != null && !lead[0]!.contains(',')) t = t.substring(lead.end);
  if (RegExp(r'[a-z)]\. [A-Z]').hasMatch(t)) {
    return [t.replaceFirst(RegExp(r'\.$'), '')];
  }
  final sep = t.contains(';') ? ';' : ',';
  final parts = <String>[];
  final buf = StringBuffer();
  var depth = 0;
  for (final ch in t.split('')) {
    if (ch == '(') depth++;
    if (ch == ')') depth = depth > 0 ? depth - 1 : 0;
    if (ch == sep && depth == 0) {
      parts.add(buf.toString());
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  parts.add(buf.toString());
  final out = <String>[];
  for (var p in parts) {
    p = p.trim().replaceFirst(RegExp(r'^(and|&) ', caseSensitive: false), '');
    p = p.replaceFirst(RegExp(r'\.$'), '').trim();
    if (p.isEmpty) continue;
    out.add(p[0].toUpperCase() + p.substring(1));
  }
  return out;
}

String _hours(String d) => d
    .replaceAll(RegExp(r'\s*\(Total Exam\)'), '')
    .replaceAll('Hours', 'hours')
    .replaceAll('Hour', 'hour');

List<SyllabusExam> _build() {
  final byName = <String, SyllabusExam>{};
  for (final s in OfficialSyllabusData.apssbSections) {
    final e = byName.putIfAbsent(s.examName,
        () => SyllabusExam(s.examName, 'APSSB', s.targetCadres, []));
    e.papers.add(SyllabusPaper(
      exam: s.examName,
      stage: s.stage,
      title: s.subject,
      facts: [
        if (s.questions != null) '${s.questions} questions',
        if (s.marks != null) '${s.marks} marks',
        _hours(s.duration),
      ],
      marking: s.markingStandard,
      topics: splitTopics(s.syllabusBreakdown),
      practical: s.isSkillTest,
    ));
  }
  for (final s in OfficialSyllabusData.appscSections) {
    final e = byName.putIfAbsent(s.examName,
        () => SyllabusExam(s.examName, 'APPSC', s.targetCadres, []));
    final none = RegExp(r'^none\b', caseSensitive: false);
    e.papers.add(SyllabusPaper(
      exam: s.examName,
      stage: s.stage,
      title: s.paperName,
      facts: ['${s.marks} marks', _hours(s.duration)],
      marking: s.negativeMarking,
      topics: splitTopics(s.primaryCurriculum),
      arunachal:
          s.arunachalComponent.isEmpty || none.hasMatch(s.arunachalComponent)
              ? null
              : s.arunachalComponent,
      weight: s.weightageImpact,
      practical: s.isInterview,
    ));
  }
  return byName.values.toList();
}

final List<SyllabusExam> syllabusExams = _build();

SyllabusExam? syllabusExamNamed(String? name) =>
    syllabusExams.where((e) => e.name == name).firstOrNull;

/// The syllabus that matches an exam goal, when there is exactly one.
String? syllabusForGoal(String goalId) => switch (goalId) {
      'apssb-cgl' => 'Combined Graduate Level (CGL)',
      'apssb-chsl' => 'Combined Higher Secondary Level (CHSL)',
      'apssb-csle' => 'Combined Secondary Level (CSL / MTS)',
      'appsc-cce' => 'APPSCCE (Civil Services)',
      _ => null,
    };

/// The student's own syllabus: the one they picked, else their exam goal's.
final mySyllabusProvider =
    NotifierProvider<MySyllabusNotifier, String?>(MySyllabusNotifier.new);

class MySyllabusNotifier extends Notifier<String?> {
  static const key = 'syllabus_exam';

  @override
  String? build() {
    final picked = ref.watch(sharedPreferencesProvider).getString(key);
    if (syllabusExamNamed(picked) != null) return picked;
    return syllabusForGoal(ref.watch(examGoalProvider).id);
  }

  Future<void> choose(String exam) async {
    state = exam;
    await ref.read(sharedPreferencesProvider).setString(key, exam);
  }
}

/// Topics marked as covered, as [SyllabusPaper.topicKey]s.
final syllabusDoneProvider =
    NotifierProvider<SyllabusDoneNotifier, Set<String>>(
        SyllabusDoneNotifier.new);

class SyllabusDoneNotifier extends Notifier<Set<String>> {
  static const key = 'syllabus_done_v1';

  @override
  Set<String> build() =>
      (ref.watch(sharedPreferencesProvider).getStringList(key) ?? const [])
          .toSet();

  void _save(Set<String> next) {
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(key, next.toList());
  }

  void toggle(String topicKey) => _save(state.contains(topicKey)
      ? ({...state}..remove(topicKey))
      : {...state, topicKey});

  void setAll(Iterable<String> keys, bool done) =>
      _save(done ? {...state, ...keys} : ({...state}..removeAll(keys)));
}
