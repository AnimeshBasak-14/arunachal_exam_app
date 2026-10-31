import 'package:arunachal_exam_app/features/learn/data/learn_deck.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final all = learnDeck.values.expand((c) => c).toList();

  test('every topic has cards', () {
    for (final t in LearnTopic.values) {
      expect(learnDeck[t], isNotEmpty, reason: t.name);
    }
    // ignore: avoid_print
    print({for (final e in learnDeck.entries) e.key.name: e.value.length}
      ..['total'] = all.length);
  });

  test('card ids are unique', () {
    final ids = all.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('quizzes are well formed', () {
    for (final c in all.where((c) => c.kind == CardKind.quiz)) {
      expect(c.options.length, greaterThanOrEqualTo(2), reason: c.id);
      expect(c.options.toSet().length, c.options.length,
          reason: '${c.id} has duplicate options');
      expect(c.answer, inInclusiveRange(0, c.options.length - 1), reason: c.id);
      expect(c.options.every((o) => o.trim().isNotEmpty), isTrue, reason: c.id);
    }
  });

  test('flip cards have an answer', () {
    for (final c in all.where((c) => c.kind == CardKind.flip)) {
      expect(c.body, isNotNull, reason: c.id);
    }
  });

  test('feed mixes topics and keeps every card', () {
    final feed = buildFeed(LearnTopic.values.toSet(), seed: 1);
    expect(feed.length, all.length);
    final firstTen = feed.take(10).map((c) => c.topic).toSet();
    expect(firstTen.length, greaterThan(3));
  });
}
