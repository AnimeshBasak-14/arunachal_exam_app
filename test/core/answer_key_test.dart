import 'package:flutter_test/flutter_test.dart';
import 'package:arunachal_exam_app/core/services/question_repository.dart';

Map<String, dynamic> _row({String? correctAnswer, String? correctOption}) => {
      'id': 'q1',
      'question_text': 'Capital of Arunachal Pradesh?',
      'options': ['(a) Itanagar', '(b) Tawang', '(c) Ziro', '(d) Pasighat'],
      'correct_answer': correctAnswer,
      'correct_option': correctOption,
    };

void main() {
  group('Answer key parsing', () {
    test('empty key is not treated as option A', () {
      final q = Question.fromSupabase(_row(correctAnswer: ''));
      expect(q.hasAnswerKey, isFalse);
      expect(q.correctAnswer, isEmpty);
      expect(q.officialAnswer, isEmpty);
    });

    test('missing key is not treated as option A', () {
      final q = Question.fromSupabase(_row());
      expect(q.hasAnswerKey, isFalse);
    });

    test('uppercase key is normalised', () {
      final q = Question.fromSupabase(_row(correctAnswer: 'B'));
      expect(q.hasAnswerKey, isTrue);
      expect(q.correctAnswer, 'b');
      expect(q.officialAnswer, '(b) Tawang');
    });

    test('correct_option takes precedence over correct_answer', () {
      final q =
          Question.fromSupabase(_row(correctAnswer: 'a', correctOption: 'c'));
      expect(q.correctAnswer, 'c');
    });
  });
}
