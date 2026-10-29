import '../../analytics/view/analytics_screen.dart';
import '../data/learn_deck.dart';
import '../../exam/data/attempt.dart';

/// Maps raw question subject names from PYQs and mocks to [LearnTopic] categories.
///
/// Returns null if the subject has no matching cards in the study deck.
LearnTopic? topicForSubject(String subject) {
  final s = subject.trim().toLowerCase();
  if (s.isEmpty) return null;

  // Specific state GK checks
  if (s.contains('arunachal') || s.contains('state gk') || s.contains('local gk')) {
    return LearnTopic.arunachal;
  }

  // Polity & Constitution
  if (s.contains('polity') || s.contains('constitution') || s.contains('governance')) {
    return LearnTopic.polity;
  }

  // History
  if (s.contains('history') || s.contains('modern india') || s.contains('freedom struggle') || s.contains('ancient') || s.contains('medieval')) {
    return LearnTopic.history;
  }

  // Geography
  if (s.contains('geography') || s.contains('physical geography') || s.contains('climate') || s.contains('drainage') || s.contains('river')) {
    return LearnTopic.geography;
  }

  // Economy
  if (s.contains('economy') || s.contains('economics') || s.contains('budget') || s.contains('economic')) {
    return LearnTopic.economy;
  }

  // Environment & Ecology
  if (s.contains('environment') || s.contains('ecology') || s.contains('biodiversity') || s.contains('wildlife') || s.contains('climate change')) {
    return LearnTopic.environment;
  }

  // Science
  if (s.contains('general science') || s.contains('science') || s.contains('physics') || s.contains('chemistry') || s.contains('biology') || s.contains('tech')) {
    return LearnTopic.science;
  }

  // English & Grammar
  if (s.contains('grammar') || s.contains('english') || s.contains('tense') || s.contains('voice') || s.contains('narration') || s.contains('preposition')) {
    return LearnTopic.grammar;
  }

  // Vocabulary
  if (s.contains('vocab') || s.contains('synonym') || s.contains('antonym') || s.contains('idiom') || s.contains('one word')) {
    return LearnTopic.vocab;
  }

  return null;
}

/// A weak subject mapped to a valid [LearnTopic] for targeted practice.
class WeakTopicSuggestion {
  final String subject;
  final LearnTopic topic;
  final int correct;
  final int attempted;

  const WeakTopicSuggestion({
    required this.subject,
    required this.topic,
    required this.correct,
    required this.attempted,
  });

  double get accuracy => attempted == 0 ? 0 : correct / attempted;
  int get accuracyPercent => (accuracy * 100).round();
}

/// Identifies the 1–3 weakest mapped subjects across attempts.
///
/// Only subjects with at least [minQuestions] answered questions are included,
/// ranked lowest accuracy first. Duplicate mapped topics are deduplicated, keeping
/// the weakest subject under that topic.
List<WeakTopicSuggestion> findWeakTopics(
  List<Attempt> attempts, {
  int max = 3,
  int minQuestions = 3,
}) {
  final stats = subjectStats(attempts);
  final out = <WeakTopicSuggestion>[];
  final seenTopics = <LearnTopic>{};

  for (final st in stats) {
    if (st.attempted < minQuestions) continue;
    final topic = topicForSubject(st.subject);
    if (topic == null) continue;
    if (seenTopics.add(topic)) {
      out.add(WeakTopicSuggestion(
        subject: st.subject,
        topic: topic,
        correct: st.correct,
        attempted: st.attempted,
      ));
      if (out.length >= max) break;
    }
  }

  return out;
}

/// Finds the weakest mapped subject from a single attempt.
WeakTopicSuggestion? findWeakTopicForAttempt(Attempt attempt, {int minQuestions = 3}) {
  final list = findWeakTopics([attempt], max: 1, minQuestions: minQuestions);
  return list.isEmpty ? null : list.first;
}
