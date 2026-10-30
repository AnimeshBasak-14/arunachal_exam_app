import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../data/grammar_data.dart';
import '../../../data/vocab_data.dart';
import '../../learn/data/learn_deck.dart';
import '../../learn/view/study_widgets.dart';

class GrammarHubScreen extends StatelessWidget {
  const GrammarHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final levels = ['Beginner', 'Intermediate', 'Advanced'];
    return StudyPage(
      title: 'English',
      track: 'english',
      coinSpot: 'english',
      children: [
        const LearnHero(
          title: 'Grammar in 60-second cards',
          subtitle:
              'One rule, one right-or-wrong sentence, then the next. Built from APSSB and APPSC error-spotting questions.',
          route: '/learn?topic=grammar',
        ),
        const SizedBox(height: 14),
        Row(children: const [
          Expanded(
              child: TopicTile(
                  topic: LearnTopic.grammar, icon: CupertinoIcons.textformat)),
          SizedBox(width: 12),
          Expanded(
              child: TopicTile(
                  topic: LearnTopic.vocab,
                  icon: CupertinoIcons.textformat_abc)),
        ]),
        const SizedBox(height: 14),
        GlassList(children: [
          GlassListRow(
            icon: CupertinoIcons.timer,
            title: 'Timed grammar test',
            subtitle: 'Exam-style questions against the clock',
            onTap: () => context.push('/grammar-quiz'),
          ),
          GlassListRow(
            icon: CupertinoIcons.book,
            title: 'Vocabulary lists',
            subtitle:
                '${VocabData.idioms.length} idioms · ${VocabData.oneWord.length} one-word substitutions · ${VocabData.spellings.length} spellings',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const _VocabScreen())),
          ),
        ]),
        const SizedBox(height: 14),
        const SavedCardsRow(),
        for (final level in levels)
          if (GrammarData.topics.any((t) => t.level == level)) ...[
            const SizedBox(height: 28),
            SectionHeader(level),
            const SizedBox(height: 12),
            GlassList(
              indent: 18,
              children: [
                for (final t
                    in GrammarData.topics.where((t) => t.level == level))
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => _TopicScreen(topic: t))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title,
                                  style: AuraType.sans(15, a.ink,
                                      weight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text('${t.rules.length} rules · ${t.subtitle}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AuraType.sans(12.5, a.inkFaint)),
                            ],
                          ),
                        ),
                        Icon(CupertinoIcons.chevron_right,
                            size: 16, color: a.inkFaint),
                      ]),
                    ),
                  ),
              ],
            ),
          ],
      ],
    );
  }
}

class _TopicScreen extends StatelessWidget {
  final GrammarTopic topic;
  const _TopicScreen({required this.topic});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final good = a.success;
    return StudyPage(
      title: topic.level,
      track: 'english',
      children: [
        Text(topic.title, style: AuraType.serif(27, a.ink, height: 1.2)),
        const SizedBox(height: 6),
        Text(topic.subtitle, style: AuraType.sans(14, a.inkMuted)),
        const SizedBox(height: 20),
        for (final r in topic.rules) ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.ruleTitle,
                    style: AuraType.sans(16, a.ink, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(r.explanation,
                    style: AuraType.sans(14.5, a.inkMuted, height: 1.55)),
                const SizedBox(height: 12),
                _line(
                    context, CupertinoIcons.checkmark, good, r.exampleCorrect),
                const SizedBox(height: 6),
                _line(context, CupertinoIcons.xmark, a.danger,
                    r.exampleIncorrect),
                if (r.tip != null) ...[
                  const SizedBox(height: 12),
                  _line(context, CupertinoIcons.lightbulb, a.review, r.tip!,
                      muted: true),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => context.push('/learn?topic=grammar'),
          icon: const Icon(CupertinoIcons.play_fill, size: 16),
          label: const Text('Practise as cards'),
        ),
      ],
    );
  }

  Widget _line(BuildContext context, IconData icon, Color c, String text,
      {bool muted = false}) {
    final a = context.aura;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 15, color: c)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style: AuraType.sans(14.5, muted ? a.inkMuted : a.ink,
                  height: 1.45))),
    ]);
  }
}

class _VocabScreen extends StatelessWidget {
  const _VocabScreen();

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    Widget list(String title, List<(String, String)> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            SectionHeader(title),
            const SizedBox(height: 10),
            GlassList(indent: 18, children: [
              for (final (term, meaning) in items)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(term,
                          style: AuraType.sans(15, a.ink,
                              weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(meaning, style: AuraType.sans(14, a.inkMuted)),
                    ],
                  ),
                ),
            ]),
          ],
        );
    return StudyPage(
      title: 'Vocabulary',
      track: 'english',
      children: [
        FilledButton.icon(
          onPressed: () => context.push('/learn?topic=vocab'),
          icon: const Icon(CupertinoIcons.play_fill, size: 16),
          label: const Text('Practise as cards'),
        ),
        list('Idioms & phrases', VocabData.idioms),
        list('One-word substitution', VocabData.oneWord),
        list('Spellings', [
          for (final s in VocabData.spellings)
            (s.first, 'Not: ${s.skip(1).join(', ')}')
        ]),
      ],
    );
  }
}
