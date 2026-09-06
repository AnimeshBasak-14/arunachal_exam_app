import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jsonEncode produces correct quiz history JSON structure', () {
    final selectedAnswers = {'q1': 'a', 'q2': 'b'};
    const examCode = 'APSSB-CGLE';
    const score = 18.0;
    const maxScore = 20.0;
    const ratingChange = 15;
    const speedBonus = 5;
    const correct = 9;
    const wrong = 1;
    const left = 0;
    const timeTaken = 180;
    const dateStr = '2025-05-20 14:30';

    final recordJson = jsonEncode({
      'examCode': examCode,
      'score': score,
      'maxScore': maxScore,
      'ratingChange': ratingChange,
      'speedBonus': speedBonus,
      'correct': correct,
      'wrong': wrong,
      'left': left,
      'timeTaken': timeTaken,
      'date': dateStr,
      'selectedAnswers': selectedAnswers,
    });

    final decoded = jsonDecode(recordJson) as Map<String, dynamic>;

    expect(decoded['examCode'], 'APSSB-CGLE');
    expect(decoded['score'], 18.0);
    expect(decoded['maxScore'], 20.0);
    expect(decoded['ratingChange'], 15);
    expect(decoded['speedBonus'], 5);
    expect(decoded['correct'], 9);
    expect(decoded['wrong'], 1);
    expect(decoded['left'], 0);
    expect(decoded['timeTaken'], 180);
    expect(decoded['date'], '2025-05-20 14:30');
    expect(decoded['selectedAnswers'], {'q1': 'a', 'q2': 'b'});
  });
}
