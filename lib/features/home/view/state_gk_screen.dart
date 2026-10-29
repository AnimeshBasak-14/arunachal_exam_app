import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../data/national_gk_data.dart';
import '../../../data/state_gk_data.dart';
import '../../learn/data/learn_deck.dart';
import '../../learn/view/study_widgets.dart';

/// GK home: swipe feed first, then the map, topics, and chapters to read.
class StateGkScreen extends StatelessWidget {
  const StateGkScreen({super.key});

  static const _topics = [
    (LearnTopic.arunachal, CupertinoIcons.location),
    (LearnTopic.polity, CupertinoIcons.building_2_fill),
    (LearnTopic.history, CupertinoIcons.time),
    (LearnTopic.geography, CupertinoIcons.globe),
    (LearnTopic.economy, CupertinoIcons.money_dollar_circle),
    (LearnTopic.environment, CupertinoIcons.tree),
    (LearnTopic.science, CupertinoIcons.lab_flask),
  ];

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final arunachal = StateGkData.chapters.where((c) => c.category != 'Science').toList();
    final general = [
      ...NationalGkData.chapters,
      ...StateGkData.chapters.where((c) => c.category == 'Science'),
    ];

    return StudyPage(
      title: 'General knowledge',
      children: [
        const LearnHero(
          title: 'GK in 60-second cards',
          subtitle: 'Swipe through facts and quick quizzes. Missed ones come back until they stick.',
          route: '/learn',
        ),
        const SizedBox(height: 14),
        _MapCard(onTap: () => context.push('/gk-map')),
        const SizedBox(height: 28),
        const SectionHeader('Practise by topic'),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 560 ? 4 : 2;
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [for (final (t, i) in _topics) TopicTile(topic: t, icon: i)],
          );
        }),
        const SizedBox(height: 14),
        const SavedCardsRow(),
        const SizedBox(height: 28),
        const SectionHeader('Arunachal Pradesh'),
        const SizedBox(height: 4),
        Text('Read the full chapters', style: AuraType.sans(13, a.inkFaint)),
        const SizedBox(height: 12),
        _ChapterList(chapters: arunachal),
        const SizedBox(height: 28),
        const SectionHeader('General studies'),
        const SizedBox(height: 12),
        _ChapterList(chapters: general),
      ],
    );
  }
}

class _MapCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MapCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: a.bgTint,
              borderRadius: BorderRadius.circular(AuraSpace.radiusS),
            ),
            child: Icon(CupertinoIcons.map, color: a.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Arunachal on the map', style: AuraType.sans(16, a.ink, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('64 places with photos · play "Find it"',
                    style: AuraType.sans(13, a.inkMuted)),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_right, size: 16, color: a.inkFaint),
        ],
      ),
    );
  }
}

class _ChapterList extends StatelessWidget {
  final List<StateGkChapter> chapters;
  const _ChapterList({required this.chapters});

  @override
  Widget build(BuildContext context) {
    return GlassList(
      indent: 18,
      children: [
        for (final c in chapters)
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChapterScreen(chapter: c),
            )),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                          style: AuraType.sans(15, context.aura.ink, weight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(c.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AuraType.sans(12.5, context.aura.inkFaint)),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, size: 16, color: context.aura.inkFaint),
              ]),
            ),
          ),
      ],
    );
  }
}

/// One chapter as a clean reading page.
class ChapterScreen extends StatelessWidget {
  final StateGkChapter chapter;
  const ChapterScreen({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final keys = chapter.keyFacts.isEmpty ? <String>[] : chapter.keyFacts.first.keys.toList();
    return StudyPage(
      title: chapter.category,
      children: [
        Text(chapter.title.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
            style: AuraType.serif(27, a.ink, height: 1.2)),
        const SizedBox(height: 6),
        Text(chapter.subtitle, style: AuraType.sans(14, a.inkMuted)),
        const SizedBox(height: 22),
        for (final h in chapter.highlights)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(color: a.accent, shape: BoxShape.circle)),
              ),
              Expanded(child: Text(h, style: AuraType.sans(15.5, a.ink, height: 1.6))),
            ]),
          ),
        if (keys.length >= 2) ...[
          const SizedBox(height: 14),
          SectionHeader('Key facts'),
          const SizedBox(height: 10),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(children: [
                  Expanded(child: Eyebrow(keys[0])),
                  const SizedBox(width: 12),
                  Expanded(child: Eyebrow(keys[1])),
                ]),
              ),
              for (final row in chapter.keyFacts) ...[
                Divider(color: a.hairline),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(row[keys[0]] ?? '', style: AuraType.sans(14, a.ink, weight: FontWeight.w500, height: 1.4))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(row[keys[1]] ?? '', style: AuraType.sans(14, a.inkMuted, height: 1.4))),
                  ]),
                ),
              ],
            ]),
          ),
        ],
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: () => context.push('/learn?topic=${_topic(chapter).name}'),
          icon: const Icon(CupertinoIcons.play_fill, size: 16),
          label: const Text('Practise as cards'),
        ),
      ],
    );
  }

  LearnTopic _topic(StateGkChapter c) =>
      learnDeck.entries.firstWhere((e) => e.value.any((card) => card.id.startsWith('${c.id}.')),
          orElse: () => MapEntry(LearnTopic.arunachal, const [])).key;
}
