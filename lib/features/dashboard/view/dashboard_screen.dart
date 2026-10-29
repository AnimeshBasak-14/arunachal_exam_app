import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/data/exam_goals.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../core/widgets/aura/exam_goal_sheet.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/streak_service.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../exam/data/attempt.dart';
import '../../learn/data/learn_deck.dart';
import '../../learn/data/learn_progress.dart';
import '../../learn/data/topic_mapping.dart';
import '../../home/view/notifications_screen.dart' show hasUnreadNotifProvider;
import '../../learn/view/study_widgets.dart';
import '../../mocks/view/live_mock_card.dart';
import '../../papers/data/paper.dart';
import '../../papers/view/paper_widgets.dart';
import '../../plan/data/study_plan_provider.dart';
import '../../plan/view/study_plan_sheet.dart';
import '../../shell/view/app_shell.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _setupPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _setupPrompted) return;
      final plan = ref.read(studyPlanProvider);
      final user = ref.read(authViewModelProvider).user;
      if (user != null && !plan.completed) {
        _setupPrompted = true;
        showStudyPlanSheet(context, isFirstRun: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(papersProvider(PaperKind.pyq));
        ref.invalidate(papersProvider(PaperKind.mock));
        await ref.read(papersProvider(PaperKind.pyq).future);
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          const SliverToBoxAdapter(child: _Header()),
          const SliverToBoxAdapter(child: SizedBox(height: 22)),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
            sliver: SliverToBoxAdapter(child: _TodayCard()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          const SliverToBoxAdapter(child: _PyqHub()),
          const SliverToBoxAdapter(child: SizedBox(height: 34)),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
            sliver: SliverToBoxAdapter(child: LiveMockCard()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 34)),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
            sliver: SliverToBoxAdapter(child: _StudyShelf()),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 110 + MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final user = ref.watch(authViewModelProvider).user;
    final firstName = (user?.name ?? '').trim().split(' ').first;
    final goal = ref.watch(examGoalProvider);
    final hasUnread = ref.watch(hasUnreadNotifProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(AuraSpace.gutter,
          MediaQuery.paddingOf(context).top + 18, AuraSpace.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Eyebrow(firstName.isEmpty
                    ? _greeting()
                    : '${_greeting()}, $firstName'),
              ),
              IconButton(
                tooltip: 'Exam alerts',
                onPressed: () => context.push('/notifications'),
                icon: Badge(
                  isLabelVisible: hasUnread,
                  smallSize: 7,
                  backgroundColor: a.accent,
                  child: Icon(CupertinoIcons.bell, size: 22, color: a.ink),
                ),
              ),
              const SizedBox(width: 2),
              Semantics(
                button: true,
                label: 'Account',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.push('/account'),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: a.accentSoft,
                      border: Border.all(color: a.hairline),
                    ),
                    child: Text(
                      firstName.isEmpty ? '·' : firstName[0].toUpperCase(),
                      style:
                          AuraType.serif(16, a.accent, weight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Preparing for', style: AuraType.sans(13, a.inkFaint)),
          const SizedBox(height: 4),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => showExamGoalSheet(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(goal.name,
                      style: AuraType.serif(29, a.ink, height: 1.18)),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 6),
                  child: Icon(CupertinoIcons.chevron_down,
                      size: 15, color: a.inkFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One calm card that answers "what should I do now?": today's progress,
/// the streak, real exam countdown, weak topic action, and a single button.
class _TodayCard extends ConsumerWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final plan = ref.watch(studyPlanProvider);
    final goal = ref.watch(dailyCardGoalProvider);
    final p = ref.watch(learnProgressProvider);
    final streaks = StreakService(ref.watch(sharedPreferencesProvider));
    final streak = streaks.getCurrentStreak();
    final best = streaks.getLongestStreak();
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final studiedToday = streaks.getLastActiveDate() == today;
    final left = (goal - p.today).clamp(0, goal);
    final done = p.today >= goal;

    final attempts = loadAttempts(ref.watch(storageServiceProvider));
    final weakTopics = findWeakTopics(attempts, max: 1);
    final weakTopic = weakTopics.isNotEmpty ? weakTopics.first : null;
    final daysUntil = plan.daysUntilExam();

    final String headline;
    final String line;
    final String cta;
    final VoidCallback onCta;

    if (daysUntil != null && daysUntil < 0) {
      headline = 'Exam date passed';
      line = 'Set your next exam date to restart your countdown.';
      cta = 'Set exam date';
      onCta = () => showStudyPlanSheet(context);
    } else {
      if (daysUntil != null) {
        headline = plan.deadlineLabel()!;
      } else if (done) {
        headline = 'Goal reached';
      } else if (studiedToday) {
        headline = '$left cards to your goal';
      } else if (streak > 0) {
        headline = '$streak-day streak';
      } else {
        headline = 'Start your streak';
      }

      if (weakTopic != null) {
        line =
            '${weakTopic.topic.label} is your weakest area (${weakTopic.accuracyPercent}%).';
        cta = 'Practise ${weakTopic.topic.label}';
        onCta = () =>
            context.push('/learn?topic=${weakTopic.topic.name}&limit=10');
      } else if (done) {
        line = 'Your $streak-day streak is safe. Come back tomorrow.';
        cta = 'Keep learning';
        onCta = () => context.push('/learn');
      } else if (studiedToday) {
        line = 'Streak is safe today. Finish the goal to build on it.';
        cta = 'Continue';
        onCta = () => context.push('/learn');
      } else if (streak > 0) {
        line =
            'Study today to keep it. $left cards, about ${(left / 6).ceil()} minutes.';
        cta = 'Keep my streak';
        onCta = () => context.push('/learn');
      } else {
        line = '$goal cards, about 5 minutes. Small, daily, and it adds up.';
        cta = 'Start today';
        onCta = () => context.push('/learn');
      }
    }

    return GlassCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Today'),
                const SizedBox(height: 6),
                Text(headline, style: AuraType.serif(23, a.ink, height: 1.2)),
                const SizedBox(height: 6),
                Text(line,
                    style: AuraType.sans(13.5, a.inkMuted, height: 1.45)),
                if (best > 1) ...[
                  const SizedBox(height: 6),
                  Text('Personal best: $best days',
                      style: AuraType.sans(12, a.inkFaint)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                  onPressed: onCta,
                  child: Text(cta),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: (p.today / goal).clamp(0, 1).toDouble(),
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: a.hairline,
                  color: a.accent,
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${p.today}',
                    style: AuraType.digits(20, a.ink, weight: FontWeight.w600)),
                Text('of $goal',
                    style: AuraType.sans(10.5, a.inkFaint)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _PyqHub extends ConsumerStatefulWidget {
  const _PyqHub();

  @override
  ConsumerState<_PyqHub> createState() => _PyqHubState();
}

class _PyqHubState extends ConsumerState<_PyqHub> {
  Department? _dept;

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final goalDept = ref.watch(examGoalProvider).department;
    final dept = _dept ?? goalDept;
    final async = ref.watch(papersProvider(PaperKind.pyq));
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    final cardHeight = 190.0 * scale;
    const depts = Department.primary;

    void openLibrary() {
      ref.read(libraryDepartmentProvider.notifier).state = dept;
      ref.read(currentTabProvider.notifier).state = 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
          child: SectionHeader('Previous Year Papers',
              actionLabel: 'View all', onAction: openLibrary),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuraSpace.gutter - 2),
          child: SegmentedTabs(
            labels: [for (final d in depts) d.label],
            selected: depts.indexOf(dept).clamp(0, depts.length - 1),
            onChanged: (i) => setState(() => _dept = depts[i]),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: cardHeight,
          child: async.when(
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const SkeletonBox(
                  width: 232, height: double.infinity, radius: 20),
            ),
            error: (_, __) => _quiet(
                context, 'Papers could not be loaded. Pull down to retry.'),
            data: (result) {
              final papers = result.byDepartment(dept);
              if (papers.isEmpty) {
                return _quiet(context,
                    'No ${dept.label} papers yet. New papers appear here once their answer keys are verified.');
              }
              final shown = papers.take(10).toList();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
                itemCount:
                    shown.length + (papers.length > shown.length ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  if (i == shown.length) {
                    return SizedBox(
                      width: 150,
                      child: GlassCard(
                        onTap: openLibrary,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.arrow_right, color: a.accent),
                              const SizedBox(height: 10),
                              Text('All ${papers.length} papers',
                                  textAlign: TextAlign.center,
                                  style: AuraType.sans(13.5, a.ink,
                                      weight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return PaperCard(paper: shown[i]);
                },
              );
            },
          ),
        ),
        if (async.value?.isOffline == true &&
            (async.value?.papers.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AuraSpace.gutter, 10, AuraSpace.gutter, 0),
            child: Text('Offline · showing saved papers',
                style: AuraType.sans(12, a.inkFaint)),
          ),
      ],
    );
  }

  Widget _quiet(BuildContext context, String text) {
    final a = context.aura;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
      child: GlassCard(
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: AuraType.sans(14, a.inkMuted, height: 1.5)),
        ),
      ),
    );
  }
}

class _StudyShelf extends StatelessWidget {
  const _StudyShelf();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Study shelf'),
        const SizedBox(height: 12),
        const LearnHero(
          title: 'Learn in 60-second cards',
          subtitle:
              'Arunachal GK, polity, history, grammar and vocabulary. Swipe, answer, repeat.',
          route: '/learn',
        ),
        const SizedBox(height: 14),
        GlassList(children: [
          GlassListRow(
            icon: CupertinoIcons.doc_text,
            title: 'Exam syllabus & pattern',
            subtitle: 'APPSC · APSSB official schemes',
            onTap: () => context.push('/syllabus'),
          ),
          GlassListRow(
            icon: CupertinoIcons.map,
            title: 'General knowledge',
            subtitle: 'Arunachal, polity, history, geography, science',
            onTap: () => context.push('/state-gk'),
          ),
          GlassListRow(
            icon: CupertinoIcons.textformat,
            title: 'English grammar & vocabulary',
            onTap: () => context.push('/grammar-hub'),
          ),
          GlassListRow(
            icon: CupertinoIcons.location,
            title: 'Arunachal on the map',
            subtitle: 'Tap places · play Find it',
            onTap: () => context.push('/gk-map'),
          ),
          GlassListRow(
            icon: CupertinoIcons.news,
            title: 'Current affairs',
            onTap: () => context.push('/current-affairs-gk'),
          ),
          GlassListRow(
            icon: CupertinoIcons.sparkles,
            title: 'Ask the AI tutor',
            onTap: () => context.push('/chatbot'),
          ),
          GlassListRow(
            icon: CupertinoIcons.bookmark,
            title: 'Bookmarked questions',
            onTap: () => context.push('/bookmarks'),
          ),
        ]),
      ],
    );
  }
}
