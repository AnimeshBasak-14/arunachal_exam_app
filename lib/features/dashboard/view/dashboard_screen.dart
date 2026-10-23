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
import '../../mocks/view/live_mock_card.dart';
import '../../papers/data/paper.dart';
import '../../papers/view/paper_widgets.dart';
import '../../shell/view/app_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  AuraSpace.gutter, 18, AuraSpace.gutter, 0),
              sliver: SliverToBoxAdapter(child: _Header()),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 34)),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Eyebrow(
                firstName.isEmpty ? _greeting() : '${_greeting()}, $firstName',
              ),
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
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: a.accentSoft,
                    border: Border.all(color: a.hairline),
                  ),
                  child: Text(
                    firstName.isEmpty ? '·' : firstName[0].toUpperCase(),
                    style: AuraType.serif(16, a.accent, weight: FontWeight.w600),
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
              itemBuilder: (_, __) => const SkeletonBox(width: 232, height: double.infinity, radius: 20),
            ),
            error: (_, __) => _quiet(context, 'Papers could not be loaded. Pull down to retry.'),
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
                padding: const EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
                itemCount: shown.length + (papers.length > shown.length ? 1 : 0),
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
        if (async.value?.isOffline == true && (async.value?.papers.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.fromLTRB(AuraSpace.gutter, 10, AuraSpace.gutter, 0),
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
        GlassList(children: [
          GlassListRow(
            icon: CupertinoIcons.doc_text,
            title: 'Exam syllabus & pattern',
            subtitle: 'APPSC · APSSB official schemes',
            onTap: () => context.push('/syllabus'),
          ),
          GlassListRow(
            icon: CupertinoIcons.map,
            title: 'Arunachal GK',
            subtitle: 'Districts, history, rivers, culture',
            onTap: () => context.push('/state-gk'),
          ),
          GlassListRow(
            icon: CupertinoIcons.textformat,
            title: 'English grammar',
            onTap: () => context.push('/grammar-hub'),
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
