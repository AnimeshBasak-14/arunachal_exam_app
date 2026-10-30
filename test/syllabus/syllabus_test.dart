import 'package:arunachal_exam_app/core/services/service_providers.dart';
import 'package:arunachal_exam_app/features/syllabus/data/syllabus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_app.dart';

void main() {
  group('splitTopics', () {
    test('commas, but not inside brackets', () {
      expect(
          splitTopics(
              'Number System (Fractions, Decimals), LCM & HCF, Ratio & Proportion.'),
          [
            'Number System (Fractions, Decimals)',
            'LCM & HCF',
            'Ratio & Proportion'
          ]);
    });

    test('semicolons when the board used them, lead-in dropped', () {
      expect(
          splitTopics(
              'Matriculation standard: Comprehension of given passages; Precis writing; Usage and vocabulary.'),
          [
            'Comprehension of given passages',
            'Precis writing',
            'Usage and vocabulary'
          ]);
    });

    test('a trailing "and" item is cleaned up', () {
      expect(
          splitTopics(
                  'Geography, Polity, and Arunachal Pradesh GK (Tribes, Festivals).')
              .last,
          'Arunachal Pradesh GK (Tribes, Festivals)');
    });

    test('prose stays whole', () {
      final t = splitTopics(
          'Height & Chest measurements as per norms. PET: 1500m race, Long Jump.');
      expect(t, hasLength(1));
    });
  });

  test('every exam has papers and every paper has topics', () {
    expect(syllabusExams.length, greaterThanOrEqualTo(10));
    for (final e in syllabusExams) {
      expect(e.papers, isNotEmpty, reason: e.name);
      expect(e.stages, isNotEmpty, reason: e.name);
      for (final p in e.papers) {
        expect(p.topics, isNotEmpty, reason: '${e.name} / ${p.title}');
        for (final t in p.topics) {
          expect(t.trim(), isNotEmpty);
        }
      }
    }
  });

  test('CGL General Awareness is split into separate topics', () {
    final cgl = syllabusExamNamed(syllabusForGoal('apssb-cgl'))!;
    final ga = cgl.papers.firstWhere((p) => p.title == 'General Awareness');
    expect(ga.topics.length, greaterThan(8));
    expect(ga.topics, contains('Indian Polity'));
  });

  test('every exam goal with one syllabus maps to a real one', () {
    for (final id in ['apssb-cgl', 'apssb-chsl', 'apssb-csle', 'appsc-cce']) {
      expect(syllabusExamNamed(syllabusForGoal(id)), isNotNull, reason: id);
    }
    expect(syllabusForGoal('appsc-other'), isNull);
  });

  test('my syllabus follows the goal until the student picks one', () async {
    final prefs = await testPrefs({'exam_goal_id': 'apssb-cgl'});
    final c = ProviderContainer(overrides: testOverrides(prefs));
    addTearDown(c.dispose);
    expect(c.read(mySyllabusProvider), 'Combined Graduate Level (CGL)');
    await c
        .read(mySyllabusProvider.notifier)
        .choose('Junior Engineer (JE) Common Exam');
    expect(c.read(mySyllabusProvider), 'Junior Engineer (JE) Common Exam');
    expect(c.read(sharedPreferencesProvider).getString(MySyllabusNotifier.key),
        'Junior Engineer (JE) Common Exam');
  });

  test('ticks are saved and can be set for a whole paper', () async {
    final prefs = await testPrefs();
    final c = ProviderContainer(overrides: testOverrides(prefs));
    addTearDown(c.dispose);
    final paper = syllabusExams.first.papers.first;
    final first = paper.topicKey(paper.topics.first);
    final n = c.read(syllabusDoneProvider.notifier);
    n.toggle(first);
    expect(c.read(syllabusDoneProvider), {first});
    n.toggle(first);
    expect(c.read(syllabusDoneProvider), isEmpty);
    n.setAll([for (final t in paper.topics) paper.topicKey(t)], true);
    expect(c.read(syllabusDoneProvider).length, paper.topics.length);
    expect(prefs.getStringList(SyllabusDoneNotifier.key)!.length,
        paper.topics.length);
  });
}
