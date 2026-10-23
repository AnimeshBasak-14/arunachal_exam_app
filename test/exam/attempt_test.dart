import 'package:flutter_test/flutter_test.dart';
import 'package:arunachal_exam_app/core/services/question_repository.dart';
import 'package:arunachal_exam_app/features/exam/data/attempt.dart';
import 'package:arunachal_exam_app/features/exam/view/question_view.dart';

void main() {
  test('records written by older versions still open', () {
    final t = Attempt.fromJson({
      'examCode': 'APSSB-CGLE',
      'score': 7.5,
      'maxScore': 20.0,
      'correct': 4,
      'wrong': 1,
      'left': 5,
      'timeTaken': 300,
      'date': '2026-09-01 10:00',
      'ratingChange': 6,
      'speedBonus': 2,
    });
    expect(t.title, 'APSSB-CGLE');
    expect(t.mode, 'exam');
    expect(t.questions, isEmpty);
    expect(t.accuracy, closeTo(0.8, 1e-9));
    expect(t.scoreRatio, closeTo(0.375, 1e-9));
  });

  test('stored questions round-trip with their answer key and marks', () {
    const q = Question(
      id: 'q1',
      examCode: 'APPSC-CCE',
      year: 2023,
      subject: 'Polity',
      questionText: 'Which article…?',
      options: ['(a) 14', '(b) 19', '(c) 21', '(d) 32'],
      correctAnswer: 'c',
      officialAnswer: '(c) 21',
      solution: 'Article 21.',
      marksPerCorrect: 1,
      negativeMarks: 0.33,
    );
    final t = Attempt.fromJson({
      'testTitle': 'APPSC CCE 2023',
      'mode': 'study',
      'selectedAnswers': {'q1': 'c'},
      'questions': [Attempt.questionToMap(q)],
    });
    final back = t.questions.single;
    expect(t.title, 'APPSC CCE 2023');
    expect(t.mode, 'study');
    expect(back.correctAnswer, 'c');
    expect(back.options, q.options);
    expect(back.subject, 'Polity');
    expect(back.marksPerCorrect, 1);
    expect(back.negativeMarks, 0.33);
    expect(t.selected['q1'], 'c');
  });

  test('option prefixes are split into letter and text', () {
    final parsed = ParsedOption.parse(['(a) Rs. 50', '(B) Rs. 60', 'Rs. 70']);
    expect(parsed.map((o) => o.letter), ['a', 'b', 'c']);
    expect(parsed.map((o) => o.text), ['Rs. 50', 'Rs. 60', 'Rs. 70']);
  });
}
