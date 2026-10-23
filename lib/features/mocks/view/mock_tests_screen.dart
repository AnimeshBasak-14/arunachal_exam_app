import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/data/exam_goals.dart';
import '../../../core/services/exam_repository.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../papers/data/paper.dart';
import '../../papers/view/paper_widgets.dart';
import 'live_mock_card.dart';

class MockTestsScreen extends ConsumerStatefulWidget {
  const MockTestsScreen({super.key});

  @override
  ConsumerState<MockTestsScreen> createState() => _MockTestsScreenState();
}

class _MockTestsScreenState extends ConsumerState<MockTestsScreen> {
  Department? _dept;
  static const _filters = <Department?>[null, ...Department.primary];

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final async = ref.watch(papersProvider(PaperKind.mock));
    final bottom = 110 + MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(papersProvider(PaperKind.mock));
        await ref.read(papersProvider(PaperKind.mock).future);
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AuraSpace.gutter, 24, AuraSpace.gutter, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mock Tests', style: AuraType.serif(30, a.ink)),
                    const SizedBox(height: 6),
                    Text('Exam-condition practice, timed and scored.',
                        style: AuraType.sans(14, a.inkMuted)),
                    const SizedBox(height: 24),
                    const LiveMockCard(),
                    const SizedBox(height: 14),
                    GlassCard(
                      onTap: () => showPracticeSheet(context),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.slider_horizontal_3,
                              color: a.accent, size: 22),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Build a practice set',
                                    style: AuraType.sans(15.5, a.ink,
                                        weight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('Pick a subject and length',
                                    style: AuraType.sans(13, a.inkMuted)),
                              ],
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_right,
                              size: 16, color: a.inkFaint),
                        ],
                      ),
                    ),
                    const SizedBox(height: 34),
                    const SectionHeader('Full-length mocks'),
                    SegmentedTabs(
                      labels: [for (final d in _filters) d?.label ?? 'All'],
                      selected: _filters.indexOf(_dept),
                      onChanged: (i) => setState(() => _dept = _filters[i]),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          async.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
              sliver: SliverList.separated(
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, __) => const SkeletonBox(height: 92, radius: 20),
              ),
            ),
            error: (_, __) => _empty(),
            data: (result) {
              final mocks = result.byDepartment(_dept);
              if (mocks.isEmpty) return _empty(hasAny: result.papers.isNotEmpty);
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
                sliver: SliverList.separated(
                  itemCount: mocks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => PaperRow(paper: mocks[i]),
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: bottom)),
        ],
      ),
    );
  }

  Widget _empty({bool hasAny = false}) => SliverToBoxAdapter(
        child: AuraEmpty(
          icon: CupertinoIcons.doc_text_search,
          title: hasAny ? 'No mocks for this board yet' : 'No mock tests to show',
          message: hasAny
              ? 'Try another board, or build a practice set above.'
              : 'Check your connection and try again.',
          actionLabel: hasAny ? null : 'Retry',
          onAction: () => ref.invalidate(papersProvider(PaperKind.mock)),
        ),
      );
}

Future<void> showPracticeSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _PracticeSheet(),
    );

class _PracticeSheet extends StatefulWidget {
  const _PracticeSheet();

  @override
  State<_PracticeSheet> createState() => _PracticeSheetState();
}

class _PracticeSheetState extends State<_PracticeSheet> {
  // label -> value matched against questions.subject on the server
  static const _subjects = {
    'Mathematics': 'Elementary Mathematics',
    'English': 'General English',
    'General Studies': 'General Studies',
    'Reasoning': 'Logical Reasoning',
    'All subjects': '',
  };
  static const _counts = [10, 20, 30, 50];

  String _subject = 'General Studies';
  int _count = 20;
  bool _study = false;
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    final pool = await ExamRepository.instance.fetchPracticeQuestions(
      subject: _subjects[_subject]!,
      count: math.min(100, _count * 2),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (pool.isEmpty) {
      messenger.showSnackBar(const SnackBar(
          content: Text('No questions found for this subject yet. Try another.')));
      return;
    }
    final picked = (List.of(pool)..shuffle()).take(_count).toList();
    navigator.pop();
    final params = {
      'paperType': 'BOTH',
      'title': '$_subject practice',
      if (_subjects[_subject]!.isNotEmpty) 'subject': _subjects[_subject]!,
      if (_study) 'study': 'true' else 'duration': '${math.max(10, picked.length)}',
    };
    router.push(
      Uri(path: '/mock-test/PRACTICE/${picked.length}', queryParameters: params)
          .toString(),
      extra: picked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => onTap(),
            labelStyle: AuraType.sans(13.5, selected ? a.accent : a.inkMuted,
                weight: FontWeight.w500),
            side: BorderSide(color: selected ? a.accent.withValues(alpha: 0.5) : a.hairline),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Practice set', style: AuraType.serif(25, a.ink)),
          const SizedBox(height: 6),
          Text('Questions drawn from previous papers and mocks.',
              style: AuraType.sans(14, a.inkMuted)),
          const SizedBox(height: 22),
          const Eyebrow('Subject'),
          const SizedBox(height: 10),
          Wrap(children: [
            for (final s in _subjects.keys)
              chip(s, s == _subject, () => setState(() => _subject = s)),
          ]),
          const SizedBox(height: 14),
          const Eyebrow('Questions'),
          const SizedBox(height: 10),
          Wrap(children: [
            for (final c in _counts)
              chip('$c', c == _count, () => setState(() => _count = c)),
          ]),
          const SizedBox(height: 14),
          const Eyebrow('Mode'),
          const SizedBox(height: 10),
          Wrap(children: [
            chip('Timed exam', !_study, () => setState(() => _study = false)),
            chip('Study with answers', _study, () => setState(() => _study = true)),
          ]),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _loading ? null : _start,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            child: _loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: a.onAccent),
                  )
                : const Text('Start practice'),
          ),
        ],
      ),
    );
  }
}
