import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../plan/data/study_plan_provider.dart';
import '../data/learn_deck.dart';
import '../data/learn_progress.dart';

/// Big entry card into the swipe feed, with today's goal and XP.
class LearnHero extends ConsumerWidget {
  final String title;
  final String subtitle;
  final String route;
  const LearnHero({super.key, required this.title, required this.subtitle, required this.route});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final p = ref.watch(learnProgressProvider);
    final goal = ref.watch(dailyCardGoalProvider);
    final pct = (p.today / goal).clamp(0.0, 1.0);
    return Material(
      color: a.tint,
      borderRadius: BorderRadius.circular(AuraSpace.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AuraSpace.radius),
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Eyebrow('Today · ${p.today}/$goal cards', color: a.onTint.withValues(alpha: 0.75))),
                Text('${p.xp} XP', style: AuraType.digits(13, a.onTint.withValues(alpha: 0.85))),
              ]),
              const SizedBox(height: 10),
              Text(title, style: AuraType.serif(25, a.onTint, height: 1.2)),
              const SizedBox(height: 6),
              Text(subtitle, style: AuraType.sans(14, a.onTint.withValues(alpha: 0.8), height: 1.45)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: a.onTint.withValues(alpha: 0.18),
                  color: a.accent,
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Icon(CupertinoIcons.play_fill, size: 15, color: a.onTint),
                const SizedBox(width: 8),
                Text(p.today == 0 ? 'Start swiping' : 'Keep going',
                    style: AuraType.sans(14.5, a.onTint, weight: FontWeight.w600)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid tile for one feed topic, showing how much of it is known.
class TopicTile extends ConsumerWidget {
  final LearnTopic topic;
  final IconData icon;
  const TopicTile({super.key, required this.topic, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final known = ref.watch(learnProgressProvider).known;
    final cards = learnDeck[topic]!;
    final quizzes = cards.where((c) => c.kind != CardKind.fact).toList();
    final got = quizzes.where((c) => known.contains(c.id)).length;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/learn?topic=${topic.name}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: a.accent),
          const SizedBox(height: 14),
          Text(topic.label, style: AuraType.sans(15, a.ink, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${cards.length} cards', style: AuraType.sans(12.5, a.inkFaint)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: quizzes.isEmpty ? 0 : got / quizzes.length,
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Saved-cards row used on both hubs.
class SavedCardsRow extends ConsumerWidget {
  const SavedCardsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(learnProgressProvider).saved.length;
    return GlassList(children: [
      GlassListRow(
        icon: CupertinoIcons.bookmark,
        title: 'Saved cards',
        subtitle: n == 0 ? 'Double-tap any card to save it' : '$n saved for revision',
        onTap: () => context.push('/learn?saved=1'),
      ),
    ]);
  }
}

/// Plain back-button page scaffold shared by the study screens.
class StudyPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const StudyPage({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuraBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              leading: IconButton(
                tooltip: 'Back',
                icon: const Icon(CupertinoIcons.back),
                onPressed: () => context.pop(),
              ),
              title: Text(title),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(AuraSpace.gutter, 8, AuraSpace.gutter,
                  40 + MediaQuery.paddingOf(context).bottom),
              sliver: SliverList.list(children: children),
            ),
          ],
        ),
      ),
    );
  }
}
