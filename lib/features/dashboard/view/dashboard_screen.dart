import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/data/exam_goals.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../core/widgets/aura/exam_goal_sheet.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../home/view/notifications_screen.dart' show hasUnreadNotifProvider;
import '../../learn/view/study_widgets.dart';
import '../../mocks/view/live_mock_card.dart';
import '../../papers/data/paper.dart';
import '../../plan/data/study_plan_provider.dart';
import '../../plan/view/study_plan_sheet.dart';
import '../../streak/data/coins.dart';
import '../../streak/data/daily.dart';
import '../../streak/data/day_key.dart';
import '../../streak/view/coin_widgets.dart';
import 'exam_timer_card.dart';

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
        ref.invalidate(dailyQuestionProvider(dayKey(DateTime.now())));
        await ref.read(papersProvider(PaperKind.pyq).future);
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          const SliverToBoxAdapter(child: _Header()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
            sliver: SliverToBoxAdapter(child: ExamTimerCard()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
            sliver: SliverToBoxAdapter(child: _DailyCard()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
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
                child: Eyebrow(_greeting()),
              ),
              const CoinPill(),
              const SizedBox(width: 4),
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

/// The PYQ of the day: one real exam question, the same for everyone on a
/// given date. Solving it counts as studying today.
class _DailyCard extends ConsumerWidget {
  const _DailyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final today = dayKey(DateTime.now());
    final async = ref.watch(dailyQuestionProvider(today));
    final result = ref.watch(dailyLogProvider)[today];
    final ready = async.isLoading || async.value != null;

    return GlassCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      onTap: () => context.push('/daily/$today'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(child: Eyebrow('PYQ of the day')),
            if (result != null)
              Tag(result.correct ? 'Solved' : 'Attempted',
                  color: result.correct ? a.success : a.review)
            else
              Row(mainAxisSize: MainAxisSize.min, children: [
                const CoinMark(size: 16),
                const SizedBox(width: 5),
                Text('+${CoinReward.dailyCorrect}',
                    style: AuraType.digits(12.5, a.inkMuted,
                        weight: FontWeight.w600)),
              ]),
          ]),
          const SizedBox(height: 10),
          ...async.when(
            loading: () => const [
              SkeletonBox(height: 18),
              SizedBox(height: 8),
              SkeletonBox(height: 18, width: 180),
            ],
            error: (_, __) =>
                [_quiet(a, "Today's question will load when you're online.")],
            data: (q) => q == null
                ? [
                    _quiet(a,
                        "Today's question isn't available yet. Pull down to retry.")
                  ]
                : [
                    Text(q.questionText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AuraType.serif(19, a.ink, height: 1.3)),
                    const SizedBox(height: 8),
                    MetaLine([
                      q.examCode,
                      q.year > 0 ? '${q.year}' : null,
                      q.subject
                    ]),
                  ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                onPressed: ready
                    ? () => context.push('/daily/$today')
                    : () => ref.invalidate(dailyQuestionProvider(today)),
                child: Text(!ready
                    ? 'Try again'
                    : result == null
                        ? 'Solve now'
                        : 'Review answer'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: () => context.push('/streak'),
              child: const Text('Streak'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _quiet(Aura a, String text) =>
      Text(text, style: AuraType.sans(14, a.inkMuted, height: 1.5));
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
