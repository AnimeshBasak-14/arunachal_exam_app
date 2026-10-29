import 'package:flutter_test/flutter_test.dart';
import 'package:arunachal_exam_app/core/services/question_repository.dart';
import 'package:arunachal_exam_app/features/exam/data/attempt.dart';
import 'package:arunachal_exam_app/features/learn/data/learn_deck.dart';
import 'package:arunachal_exam_app/features/learn/data/topic_mapping.dart';

void main() {
  group('topicForSubject mapping', () {
    test('maps common subjects correctly', () {
      expect(topicForSubject('Polity'), LearnTopic.polity);
      expect(topicForSubject('Indian Polity & Constitution'), LearnTopic.polity);
      expect(topicForSubject('Modern History'), LearnTopic.history);
      expect(topicForSubject('Geography of India'), LearnTopic.geography);
      expect(topicForSubject('Indian Economy'), LearnTopic.economy);
      expect(topicForSubject('General Science'), LearnTopic.science);
      expect(topicForSubject('Environment & Ecology'), LearnTopic.environment);
      expect(topicForSubject('English Grammar'), LearnTopic.grammar);
      expect(topicForSubject('Arunachal Pradesh GK'), LearnTopic.arunachal);
      expect(topicForSubject('Vocabulary Synonyms'), LearnTopic.vocab);
    });

    test('returns null for unknown or empty subjects', () {
      expect(topicForSubject(''), isNull);
      expect(topicForSubject('   '), isNull);
      expect(topicForSubject('Logical Reasoning'), isNull);
      expect(topicForSubject('Quantitative Aptitude'), isNull);
    });
  });

  group('findWeakTopics', () {
    Question q(String id, String subject, String correct) => Question(
          id: id,
          questionText: 'Question $id',
          subject: subject,
          topic: '',
          examCode: 'EX1',
          year: 2024,
          options: const ['A. 1', 'B. 2'],
          correctAnswer: correct.toLowerCase(),
          officialAnswer: correct.toLowerCase(),
          solution: 'Solution $id',
        );

    Attempt makeAttempt({
      required Map<String, String> answers,
      required List<Question> questions,
    }) {
      return Attempt(
        title: 'Test',
        examCode: 'EX1',
        mode: 'exam',
        score: 10,
        maxScore: 20,
        correct: 5,
        wrong: 5,
        left: 0,
        ungraded: 0,
        timeTaken: 100,
        date: '2026-10-29',
        ratingChange: 0,
        speedBonus: 0,
        selected: answers,
        questions: questions,
        raw: const {},
      );
    }

    test('ignores subjects with fewer than minQuestions answered', () {
      final qs = [
        q('1', 'Polity', 'a'),
        q('2', 'Polity', 'a'),
      ];
      final attempt = makeAttempt(answers: {'1': 'a', '2': 'b'}, questions: qs);
      final weak = findWeakTopics([attempt], minQuestions: 3);
      expect(weak, isEmpty);
    });

    test('ranks lowest accuracy first and maps to LearnTopic', () {
      final qs = [
        // Polity: 1 of 3 correct = 33%
        q('p1', 'Polity', 'A'),
        q('p2', 'Polity', 'A'),
        q('p3', 'Polity', 'A'),
        // History: 2 of 3 correct = 66%
        q('h1', 'History', 'A'),
        q('h2', 'History', 'A'),
        q('h3', 'History', 'A'),
        // Science: 3 of 3 correct = 100%
        q('s1', 'Science', 'A'),
        q('s2', 'Science', 'A'),
        q('s3', 'Science', 'A'),
      ];
      final answers = {
        'p1': 'a', 'p2': 'b', 'p3': 'b', // 1/3
        'h1': 'a', 'h2': 'a', 'h3': 'b', // 2/3
        's1': 'a', 's2': 'a', 's3': 'a', // 3/3
      };
      final attempt = makeAttempt(answers: answers, questions: qs);
      final weak = findWeakTopics([attempt]);

      expect(weak.length, 3);
      expect(weak[0].topic, LearnTopic.polity);
      expect(weak[0].accuracyPercent, 33);
      expect(weak[1].topic, LearnTopic.history);
      expect(weak[1].accuracyPercent, 67);
      expect(weak[2].topic, LearnTopic.science);
      expect(weak[2].accuracyPercent, 100);
    });

    test('deduplicates multiple subjects mapping to the same topic', () {
      final qs = [
        q('p1', 'Polity', 'A'),
        q('p2', 'Polity', 'A'),
        q('p3', 'Polity', 'A'),
        q('c1', 'Constitution', 'A'),
        q('c2', 'Constitution', 'A'),
        q('c3', 'Constitution', 'A'),
      ];
      final answers = {
        'p1': 'b', 'p2': 'b', 'p3': 'b', // 0/3 (Polity)
        'c1': 'a', 'c2': 'b', 'c3': 'b', // 1/3 (Constitution -> Polity)
      };
      final attempt = makeAttempt(answers: answers, questions: qs);
      final weak = findWeakTopics([attempt]);

      expect(weak.length, 1);
      expect(weak.first.topic, LearnTopic.polity);
      expect(weak.first.subject, 'Polity');
    });
  });
}
