import 'dart:math' as math;
import '../../../data/gk_places.dart';
import '../../../data/grammar_data.dart';
import '../../../data/national_gk_data.dart';
import '../../../data/state_gk_data.dart';
import '../../../data/vocab_data.dart';

enum LearnTopic { arunachal, polity, history, geography, economy, environment, science, grammar, vocab }

extension LearnTopicLabel on LearnTopic {
  String get label => switch (this) {
        LearnTopic.arunachal => 'Arunachal',
        LearnTopic.polity => 'Polity',
        LearnTopic.history => 'History',
        LearnTopic.geography => 'Geography',
        LearnTopic.economy => 'Economy',
        LearnTopic.environment => 'Environment',
        LearnTopic.science => 'Science',
        LearnTopic.grammar => 'Grammar',
        LearnTopic.vocab => 'Vocabulary',
      };
}

enum CardKind { fact, quiz, flip }

/// One screen of the Learn feed.
class LearnCard {
  final String id;
  final LearnTopic topic;
  final CardKind kind;

  /// Small label above the prompt: chapter name, "Spot the error", etc.
  final String eyebrow;
  final String prompt;

  /// Fact cards: supporting text. Flip cards: the hidden answer.
  final String? body;
  final List<String> options;
  final int answer;
  final String? explain;

  /// Grammar fact cards show a right/wrong pair.
  final String? good, bad;

  /// Set when the card is about a place on the GK map.
  final GkPlace? place;

  const LearnCard({
    required this.id,
    required this.topic,
    required this.kind,
    required this.eyebrow,
    required this.prompt,
    this.body,
    this.options = const [],
    this.answer = 0,
    this.explain,
    this.good,
    this.bad,
    this.place,
  });
}

/// Every card, grouped by topic. Built once from the study data.
final Map<LearnTopic, List<LearnCard>> learnDeck = _build();

Map<LearnTopic, List<LearnCard>> _build() {
  final deck = {for (final t in LearnTopic.values) t: <LearnCard>[]};
  void add(LearnCard c) => deck[c.topic]!.add(c);

  // ── GK chapters: highlights become facts, key-fact tables become quizzes.
  for (final ch in [...StateGkData.chapters, ...NationalGkData.chapters]) {
    final topic = _topicFor(ch);
    final name = ch.title.replaceFirst(RegExp(r'^\d+\.\s*'), '');
    for (int i = 0; i < ch.highlights.length; i++) {
      add(LearnCard(
        id: '${ch.id}.h$i',
        topic: topic,
        kind: CardKind.fact,
        eyebrow: name,
        prompt: ch.highlights[i],
      ));
    }
    _tableQuizzes(ch, topic, name).forEach(add);
  }

  // ── Places: where is it?
  final districts = gkPlaces
      .map((p) => p.district)
      .where((d) => !d.contains('·') && !d.contains('Assam') && !d.contains('Capital'))
      .toSet()
      .toList();
  for (final p in gkPlaces) {
    add(LearnCard(
      id: 'place.${p.wiki}.f',
      topic: LearnTopic.arunachal,
      kind: CardKind.fact,
      eyebrow: '${p.kind.label} · ${p.district}',
      prompt: p.name,
      body: p.facts.join('\n'),
      place: p,
    ));
    if (p.kind != PlaceKind.district && districts.contains(p.district)) {
      final opts = _pickOptions(p.district, districts, 'place.${p.wiki}');
      add(LearnCard(
        id: 'place.${p.wiki}.q',
        topic: LearnTopic.arunachal,
        kind: CardKind.quiz,
        eyebrow: 'Which district?',
        prompt: p.name,
        options: opts,
        answer: opts.indexOf(p.district),
        explain: p.facts.first,
        place: p,
      ));
    }
  }

  // ── Grammar rules: learn the rule, then pick the correct sentence.
  for (final t in GrammarData.topics) {
    for (int i = 0; i < t.rules.length; i++) {
      final r = t.rules[i];
      final good = _sentence(r.exampleCorrect), bad = _sentence(r.exampleIncorrect);
      add(LearnCard(
        id: 'gr.${t.id}.$i.f',
        topic: LearnTopic.grammar,
        kind: CardKind.fact,
        eyebrow: t.title,
        prompt: r.ruleTitle.replaceFirst(RegExp(r'^(Rule )?\d+[:.]\s*'), ''),
        body: r.explanation,
        good: good,
        bad: bad,
        explain: r.tip,
      ));
      if (good != bad) {
        final flip = '${t.id}$i'.hashCode.isEven;
        add(LearnCard(
          id: 'gr.${t.id}.$i.q',
          topic: LearnTopic.grammar,
          kind: CardKind.quiz,
          eyebrow: 'Which sentence is correct?',
          prompt: t.title,
          options: flip ? [bad, good] : [good, bad],
          answer: flip ? 1 : 0,
          explain: r.explanation,
        ));
      }
    }
  }
  for (final q in GrammarData.quizQuestions) {
    add(LearnCard(
      id: 'gq.${q.id}',
      topic: LearnTopic.grammar,
      kind: CardKind.quiz,
      eyebrow: q.category,
      prompt: q.questionText,
      options: [for (final o in q.options) o.replaceFirst(RegExp(r'^\([a-d]\)\s*'), '')],
      answer: 'abcd'.indexOf(q.correctAnswer),
      explain: q.explanation,
    ));
  }

  // ── Vocabulary.
  void pairs(String set, String label, List<(String, String)> list) {
    final meanings = [for (final p in list) p.$2];
    for (final (term, meaning) in list) {
      final id = 'v.$set.$term';
      add(LearnCard(
        id: '$id.flip',
        topic: LearnTopic.vocab,
        kind: CardKind.flip,
        eyebrow: label,
        prompt: term,
        body: meaning,
      ));
      final opts = _pickOptions(meaning, meanings, id);
      add(LearnCard(
        id: '$id.q',
        topic: LearnTopic.vocab,
        kind: CardKind.quiz,
        eyebrow: '$label · meaning?',
        prompt: term,
        options: opts,
        answer: opts.indexOf(meaning),
      ));
    }
  }

  pairs('idiom', 'Idiom', VocabData.idioms);
  pairs('one', 'One-word substitution', [for (final (w, m) in VocabData.oneWord) (m, w)]);
  for (final s in VocabData.spellings) {
    final opts = [...s]..shuffle(math.Random(s.first.hashCode));
    add(LearnCard(
      id: 'v.spell.${s.first}',
      topic: LearnTopic.vocab,
      kind: CardKind.quiz,
      eyebrow: 'Spelling',
      prompt: 'Choose the correct spelling',
      options: opts,
      answer: opts.indexOf(s.first),
    ));
  }
  return deck;
}

LearnTopic _topicFor(StateGkChapter ch) {
  if (ch.category == 'Science') return LearnTopic.science;
  return switch (ch.category) {
    'Polity' when ch.id.startsWith('pol') => LearnTopic.polity,
    'History' when ch.id.startsWith('his') => LearnTopic.history,
    'Geography' when ch.id.startsWith('geo') => LearnTopic.geography,
    'Economy' => LearnTopic.economy,
    'Environment' when ch.id.startsWith('env') => LearnTopic.environment,
    _ => LearnTopic.arunachal,
  };
}

/// Two-column tables become "match the pair" quizzes, with wrong options
/// drawn from the same column. Tables whose answers repeat or run long are
/// shown as flip cards instead.
List<LearnCard> _tableQuizzes(StateGkChapter ch, LearnTopic topic, String name) {
  final rows = ch.keyFacts.where((r) => r.length == 2).toList();
  if (rows.length < 4) return const [];
  final keys = rows.first.keys.toList();
  if (rows.any((r) => !r.containsKey(keys[0]) || !r.containsKey(keys[1]))) {
    return const [];
  }
  final answers = [for (final r in rows) r[keys[1]]!];
  final quizzable = !_mixedTables.contains(ch.id) &&
      answers.toSet().length >= 4 &&
      answers.every((a) => a.length <= 70);

  return [
    for (int i = 0; i < rows.length; i++)
      if (quizzable)
        () {
          final opts = _pickOptions(answers[i], answers, '${ch.id}.t$i');
          return LearnCard(
            id: '${ch.id}.t$i',
            topic: topic,
            kind: CardKind.quiz,
            eyebrow: '$name · ${keys[1]}',
            prompt: _unnumber(rows[i][keys[0]]!),
            options: opts,
            answer: opts.indexOf(answers[i]),
          );
        }()
      else
        LearnCard(
          id: '${ch.id}.t$i',
          topic: topic,
          kind: CardKind.flip,
          eyebrow: '$name · ${keys[1]}',
          prompt: _unnumber(rows[i][keys[0]]!),
          body: answers[i],
        ),
  ];
}

/// Tables whose rows are different kinds of fact (a peak, a pass, a bridge),
/// or whose answers repeat, so wrong options would give the answer away.
const _mixedTables = {'ch4', 'ch6', 'ch8', 'ch10'};

String _unnumber(String s) => s.replaceFirst(RegExp(r'^\d+\.\s*'), '');

/// The right answer plus up to three distinct wrong ones, in a stable order.
List<String> _pickOptions(String right, List<String> pool, String seed) {
  final rng = math.Random(seed.hashCode);
  final wrong = pool.where((p) => p != right).toSet().toList()..shuffle(rng);
  return [right, ...wrong.take(3)]..shuffle(rng);
}

/// Drops notes like "(Missing verb)" and keeps the result of "A -> B".
String _sentence(String s) {
  var out = s.contains('->') ? s.split('->').last : s;
  out = out.replaceAll(RegExp(r'\s*\((OR|Fragment|Missing|Incomplete)[^)]*\)'), '');
  return out.trim();
}

/// A feed that mixes topics so no topic or card type runs on too long.
List<LearnCard> buildFeed(Set<LearnTopic> topics, {required int seed}) {
  final rng = math.Random(seed);
  final queues = [
    for (final t in topics)
      if (learnDeck[t]!.isNotEmpty) [...learnDeck[t]!]..shuffle(rng)
  ];
  final out = <LearnCard>[];
  while (queues.any((q) => q.isNotEmpty)) {
    for (final q in queues..shuffle(rng)) {
      if (q.isEmpty) continue;
      // Take a short run from each topic so related cards sit together.
      for (int i = 0; i < 1 + rng.nextInt(2) && q.isNotEmpty; i++) {
        out.add(q.removeLast());
      }
    }
  }
  return out;
}
