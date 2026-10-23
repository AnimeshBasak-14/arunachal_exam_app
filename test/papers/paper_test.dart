import 'package:flutter_test/flutter_test.dart';
import 'package:arunachal_exam_app/core/data/exam_goals.dart';
import 'package:arunachal_exam_app/features/papers/data/paper.dart';

void main() {
  group('Paper.fromSupabase', () {
    test('missing fields stay null instead of being guessed', () {
      final p = Paper.fromSupabase({
        'id': 't1',
        'title': 'VOCAB NOTES',
        'exam_code': null,
        'questions': [
          {'count': 12}
        ],
      }, PaperKind.pyq);

      expect(p.year, isNull);
      expect(p.subject, isNull);
      expect(p.shift, isNull);
      expect(p.durationMinutes, isNull);
      expect(p.marksPerCorrect, isNull);
      expect(p.negativeMarks, isNull);
      expect(p.questionCount, 12);
      expect(p.department, Department.other);
    });

    test('reads the real question count, official count and shift', () {
      final p = Paper.fromSupabase({
        'id': 't2',
        'title': 'APSSB CGL 2024',
        'exam_code': 'apssb-cgle-2024',
        'year': 2024,
        'shift': '2',
        'total_questions': 100,
        'duration_minutes': 120,
        'marks_per_correct': 2,
        'negative_marks': 0.5,
        'questions': [
          {'count': 54}
        ],
      }, PaperKind.pyq);

      expect(p.examCode, 'APSSB-CGLE-2024');
      expect(p.shortCode, 'CGLE');
      expect(p.department, Department.apssb);
      expect(p.questionCount, 54);
      expect(p.officialQuestionCount, 100);
      expect(p.isIncomplete, isTrue);
      expect(p.shiftLabel, 'Shift 2');
      expect(p.effectiveDuration, 120);
    });

    test('paper with no questions reports a zero count', () {
      final p = Paper.fromSupabase(
          {'id': 'g', 'title': 'Ghost', 'questions': []}, PaperKind.mock);
      expect(p.questionCount, 0);
    });
  });

  test('department classification', () {
    expect(Department.classify('APPSC-CCE-2023'), Department.appsc);
    expect(Department.classify('APSSB-CHSL'), Department.apssb);
    expect(Department.classify('AP-POLICE-CONSTABLE-2022'), Department.police);
    expect(Department.classify('XYZ', board: 'APPSC'), Department.appsc);
  });

  test('duration falls back to one minute per question, minimum 10', () {
    const small = Paper(
        id: 'a', kind: PaperKind.pyq, title: 'a', examCode: 'APPSC',
        department: Department.appsc, questionCount: 5);
    const big = Paper(
        id: 'b', kind: PaperKind.pyq, title: 'b', examCode: 'APPSC',
        department: Department.appsc, questionCount: 80);
    expect(small.effectiveDuration, 10);
    expect(big.effectiveDuration, 80);
  });

  test('exam route carries the test id, title and mode', () {
    const p = Paper(
      id: 'abc-123',
      kind: PaperKind.pyq,
      title: 'APPSC CCE 2023 Paper I',
      examCode: 'APPSC-CCE',
      department: Department.appsc,
      questionCount: 100,
      year: 2023,
      durationMinutes: 120,
    );
    final exam = Uri.parse(p.examRoute(study: false));
    expect(exam.path, '/mock-test/APPSC-CCE/full');
    expect(exam.queryParameters['testId'], 'abc-123');
    expect(exam.queryParameters['paperType'], 'PYQ');
    expect(exam.queryParameters['duration'], '120');
    expect(exam.queryParameters['title'], 'APPSC CCE 2023 Paper I');
    expect(exam.queryParameters.containsKey('study'), isFalse);

    final study = Uri.parse(p.examRoute(study: true));
    expect(study.queryParameters['study'], 'true');
    expect(study.queryParameters.containsKey('duration'), isFalse);
  });

  test('json round trip keeps every field', () {
    const p = Paper(
      id: 'x',
      kind: PaperKind.mock,
      title: 'Mock 1',
      examCode: 'APSSB-MOCK',
      department: Department.apssb,
      questionCount: 20,
      officialQuestionCount: 25,
      year: 2025,
      shift: 'Morning',
      difficulty: 'Hard',
      durationMinutes: 30,
      marksPerCorrect: 1,
      negativeMarks: 0.25,
    );
    final r = Paper.fromJson(p.toJson());
    expect(r.kind, PaperKind.mock);
    expect(r.questionCount, 20);
    expect(r.officialQuestionCount, 25);
    expect(r.shift, 'Morning');
    expect(r.negativeMarks, 0.25);
    expect(r.department, Department.apssb);
  });
}
