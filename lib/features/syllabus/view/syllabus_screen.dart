import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../data/official_syllabus_data.dart';
import '../../streak/data/time_tracker.dart';
import '../../streak/view/coin_widgets.dart';
import '../data/syllabus.dart';

/// Your exam's syllabus as a checklist: tick topics as you cover them and
/// watch each paper fill up. Other exams are one search away.
class SyllabusScreen extends ConsumerStatefulWidget {
  /// Kept for old links (`/syllabus?tab=`); the page now opens on the
  /// student's own syllabus.
  final int initialTabIndex;
  const SyllabusScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends ConsumerState<SyllabusScreen> {
  /// An exam opened from search, when it isn't the student's own.
  String? _viewing;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// A different exam starts at its top, not wherever the last one was.
  void _show(String? viewing) {
    setState(() => _viewing = viewing);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) => TimeTracked(
        section: 'read',
        sub: 'syllabus',
        child: _page(context),
      );

  Widget _page(BuildContext context) {
    final mine = ref.watch(mySyllabusProvider);
    final exam = syllabusExamNamed(_viewing ?? mine);
    final bottom = 40 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: AuraBackground(
        child: StatusBarScrim(
          child: CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            slivers: [
              AuraSliverBar(
                title: const Text('Syllabus'),
                onBack: () => context.pop(),
                actions: [
                  const HiddenCoin('syllabus'),
                  IconButton(
                    tooltip: 'Other exams',
                    icon: const Icon(CupertinoIcons.search),
                    onPressed: () => _search(context),
                  ),
                ],
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    AuraSpace.gutter, 6, AuraSpace.gutter, bottom),
                sliver: exam == null
                    ? SliverList.list(children: [_Pick(onPick: _choose)])
                    : SliverList.list(children: [
                        if (exam.name != mine)
                          _ViewingBanner(
                            exam: exam,
                            onMakeMine: () => _choose(exam.name),
                            onBack: mine == null ? null : () => _show(null),
                          ),
                        _ExamHeader(exam: exam, mine: exam.name == mine),
                        const SizedBox(height: 22),
                        for (final stage in exam.stages) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Eyebrow(stage),
                          ),
                          for (final p in exam.papers
                              .where((p) => p.stage == stage)) ...[
                            _PaperCard(paper: p),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'From the boards\' published syllabus. Always check the latest official notification before the exam.',
                          style: AuraType.sans(12, a(context).inkFaint,
                              height: 1.45),
                        ),
                      ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Aura a(BuildContext context) => context.aura;

  Future<void> _choose(String exam) async {
    await ref.read(mySyllabusProvider.notifier).choose(exam);
    if (mounted) _show(null);
  }

  Future<void> _search(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AllSyllabi(),
    );
    if (picked != null && mounted) _show(picked);
  }
}

class _ExamHeader extends ConsumerWidget {
  final SyllabusExam exam;
  final bool mine;
  const _ExamHeader({required this.exam, required this.mine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final done = ref.watch(syllabusDoneProvider);
    final keys = exam.topicKeys.toList();
    final n = keys.where(done.contains).length;
    final next = [
      for (final p in exam.papers)
        for (final t in p.topics)
          if (!done.contains(p.topicKey(t))) t
    ].firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(mine ? 'Your syllabus · ${exam.board}' : exam.board,
            color: a.accent),
        const SizedBox(height: 6),
        Text(exam.name, style: AuraType.serif(26, a.ink, height: 1.2)),
        const SizedBox(height: 6),
        Text(exam.cadres, style: AuraType.sans(13.5, a.inkMuted, height: 1.45)),
        const SizedBox(height: 18),
        GlassCard(
          child: Row(children: [
            _Ring(done: n, total: keys.length, size: 64),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      n == 0
                          ? 'Nothing ticked yet'
                          : n == keys.length
                              ? 'Whole syllabus covered'
                              : '$n of ${keys.length} topics covered',
                      style:
                          AuraType.sans(15.5, a.ink, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    next == null
                        ? 'Revise with mock tests and previous papers.'
                        : 'Next up: $next',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AuraType.sans(13, a.inkMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  final int done, total;
  final double size;
  const _Ring({required this.done, required this.total, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final v = total == 0 ? 0.0 : done / total;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: v),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => Stack(alignment: Alignment.center, children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: t,
              strokeWidth: size > 50 ? 6 : 4,
              strokeCap: StrokeCap.round,
              backgroundColor: a.hairline,
              color: v >= 1 ? a.success : a.accent,
            ),
          ),
          Text('${(t * 100).round()}%',
              style: AuraType.digits(size > 50 ? 15 : 11, a.ink)),
        ]),
      ),
    );
  }
}

/// One paper: pattern, a progress bar, and (when opened) its topics.
class _PaperCard extends ConsumerStatefulWidget {
  final SyllabusPaper paper;
  const _PaperCard({required this.paper});

  @override
  ConsumerState<_PaperCard> createState() => _PaperCardState();
}

class _PaperCardState extends ConsumerState<_PaperCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final p = widget.paper;
    final done = ref.watch(syllabusDoneProvider);
    final keys = [for (final t in p.topics) p.topicKey(t)];
    final n = keys.where(done.contains).length;
    final all = n == keys.length && keys.isNotEmpty;
    final practise = _practiseRoute(p.title);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          borderRadius: BorderRadius.circular(AuraSpace.radius),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _open = !_open);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text(p.title,
                      style: AuraType.sans(15.5, a.ink,
                          weight: FontWeight.w600, height: 1.3)),
                ),
                const SizedBox(width: 8),
                Text('$n/${keys.length}',
                    style: AuraType.digits(13, all ? a.success : a.inkMuted)),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(CupertinoIcons.chevron_down,
                      size: 16, color: a.inkFaint),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                [...p.facts, if (p.practical) 'Practical'].join(' · '),
                style: AuraType.sans(12.5, a.inkMuted),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: keys.isEmpty ? 0 : n / keys.length),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 5,
                    backgroundColor: a.hairline,
                    color: all ? a.success : a.accent,
                  ),
                ),
              ),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: a.hairline, height: 1),
                    const SizedBox(height: 4),
                    for (final t in p.topics)
                      _TopicRow(
                        text: t,
                        done: done.contains(p.topicKey(t)),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(syllabusDoneProvider.notifier)
                              .toggle(p.topicKey(t));
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                      child: Text('Marking: ${p.marking}',
                          style: AuraType.sans(12.5, a.inkMuted, height: 1.45)),
                    ),
                    if (p.weight != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                        child: Text(p.weight!,
                            style:
                                AuraType.sans(12.5, a.inkMuted, height: 1.45)),
                      ),
                    if (p.arunachal != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: a.bgTint,
                          borderRadius:
                              BorderRadius.circular(AuraSpace.radiusS),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Eyebrow('Arunachal focus', color: a.accent),
                            const SizedBox(height: 6),
                            Text(p.arunachal!,
                                style:
                                    AuraType.sans(13.5, a.ink, height: 1.45)),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
                      child: Row(children: [
                        TextButton(
                          onPressed: keys.isEmpty
                              ? null
                              : () => ref
                                  .read(syllabusDoneProvider.notifier)
                                  .setAll(keys, !all),
                          child: Text(all ? 'Clear ticks' : 'Mark all covered'),
                        ),
                        const Spacer(),
                        if (practise != null)
                          TextButton.icon(
                            onPressed: () => context.push(practise),
                            icon:
                                const Icon(CupertinoIcons.play_fill, size: 13),
                            label: const Text('Practise'),
                          ),
                      ]),
                    ),
                  ],
                ),
        ),
      ]),
    );
  }

  /// Where to practise a paper in the app, when we have material for it.
  static String? _practiseRoute(String title) {
    final t = title.toLowerCase();
    if (t.contains('english')) return '/grammar-hub';
    if (t.contains('awareness') ||
        t.contains('general studies') ||
        t.contains('general knowledge') ||
        t.contains('paper-i: general')) {
      return '/state-gk';
    }
    return null;
  }
}

class _TopicRow extends StatelessWidget {
  final String text;
  final bool done;
  final VoidCallback onTap;
  const _TopicRow(
      {required this.text, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Semantics(
      checked: done,
      button: true,
      label: text,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? a.success : Colors.transparent,
                border: Border.all(
                    color: done ? a.success : a.inkFaint, width: 1.6),
              ),
              child: AnimatedScale(
                scale: done ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(Icons.check_rounded, size: 15, color: a.bg),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AuraType.sans(14.5, done ? a.inkMuted : a.ink,
                    height: 1.45),
                child: Text(text),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ViewingBanner extends StatelessWidget {
  final SyllabusExam exam;
  final VoidCallback onMakeMine;
  final VoidCallback? onBack;
  const _ViewingBanner(
      {required this.exam, required this.onMakeMine, this.onBack});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: a.bgTint,
        borderRadius: BorderRadius.circular(AuraSpace.radiusS),
      ),
      child: Row(children: [
        Expanded(
          child: Text('Just looking. This isn\'t your syllabus.',
              style: AuraType.sans(13, a.inkMuted)),
        ),
        if (onBack != null)
          TextButton(onPressed: onBack, child: const Text('Back to mine')),
        TextButton(onPressed: onMakeMine, child: const Text('Make it mine')),
      ]),
    );
  }
}

/// Shown when the exam goal maps to several syllabi (APPSC technical posts).
class _Pick extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _Pick({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Which exam are you preparing for?',
          style: AuraType.serif(24, a.ink, height: 1.25)),
      const SizedBox(height: 6),
      Text('We\'ll show only that syllabus. You can change it any time.',
          style: AuraType.sans(14, a.inkMuted)),
      const SizedBox(height: 16),
      _ExamList(exams: syllabusExams, onPick: onPick),
    ]);
  }
}

class _ExamList extends ConsumerWidget {
  final List<SyllabusExam> exams;
  final ValueChanged<String> onPick;
  const _ExamList({required this.exams, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final done = ref.watch(syllabusDoneProvider);
    final mine = ref.watch(mySyllabusProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final board in ['APSSB', 'APPSC'])
        if (exams.any((e) => e.board == board)) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Eyebrow(board),
          ),
          GlassList(indent: 18, children: [
            for (final e in exams.where((e) => e.board == board))
              InkWell(
                onTap: () => onPick(e.name),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(
                              child: Text(e.name,
                                  style: AuraType.sans(15, a.ink,
                                      weight: FontWeight.w500)),
                            ),
                            if (e.name == mine) ...[
                              const SizedBox(width: 8),
                              Tag('Yours', color: a.accent),
                            ],
                          ]),
                          const SizedBox(height: 2),
                          Text(e.cadres,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AuraType.sans(12.5, a.inkFaint)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _Ring(
                        done: e.topicKeys.where(done.contains).length,
                        total: e.topicKeys.length,
                        size: 34),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 14),
        ],
    ]);
  }
}

/// Search every exam and topic; pick one to view it.
class _AllSyllabi extends StatefulWidget {
  const _AllSyllabi();

  @override
  State<_AllSyllabi> createState() => _AllSyllabiState();
}

class _AllSyllabiState extends State<_AllSyllabi> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final q = _q.trim().toLowerCase();
    bool hit(SyllabusExam e) =>
        q.isEmpty ||
        e.name.toLowerCase().contains(q) ||
        e.cadres.toLowerCase().contains(q) ||
        e.papers.any((p) =>
            p.title.toLowerCase().contains(q) ||
            p.topics.any((t) => t.toLowerCase().contains(q)));
    final shown = syllabusExams.where(hit).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(AuraSpace.gutter, 12, AuraSpace.gutter,
            24 + MediaQuery.paddingOf(context).bottom),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: a.hairline, borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: 16),
          Text('All syllabi', style: AuraType.serif(24, a.ink)),
          const SizedBox(height: 12),
          TextField(
            autofocus: false,
            onChanged: (v) => setState(() => _q = v),
            decoration: const InputDecoration(
              hintText: 'Search exams, posts or topics',
              prefixIcon: Icon(CupertinoIcons.search, size: 18),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No exam or topic matches "$_q".',
                  style: AuraType.sans(14, a.inkMuted)),
            )
          else
            _ExamList(
                exams: shown, onPick: (n) => Navigator.of(context).pop(n)),
          GlassListRow(
            icon: CupertinoIcons.arrow_right_arrow_left,
            title: 'How APSSB and APPSC differ',
            subtitle: 'Marking, negative marking, stages',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _CompareScreen())),
          ),
        ],
      ),
    );
  }
}

class _CompareScreen extends StatelessWidget {
  const _CompareScreen();

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    Widget row(String who, String text) {
      final isUrl = text.startsWith('http');
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 62,
            child: Text(who,
                style:
                    AuraType.sans(12.5, a.inkFaint, weight: FontWeight.w600))),
        Expanded(
          child: isUrl
              ? InkWell(
                  onTap: () => openLink(context, text),
                  child: Text(text.replaceFirst('https://', ''),
                      style: AuraType.sans(14.5, a.accent,
                          weight: FontWeight.w600)),
                )
              : Text(text, style: AuraType.sans(14.5, a.ink, height: 1.45)),
        ),
      ]);
    }

    return Scaffold(
      body: AuraBackground(
        child: StatusBarScrim(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const AuraSliverBar(title: Text('APSSB vs APPSC')),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    AuraSpace.gutter,
                    6,
                    AuraSpace.gutter,
                    40 + MediaQuery.paddingOf(context).bottom),
                sliver: SliverList.list(children: [
                  Text(
                      'APSSB recruits Group C posts; APPSC recruits Group A and B. '
                      'Their marking rules differ, and that changes how you attempt the paper.',
                      style: AuraType.sans(14.5, a.inkMuted, height: 1.55)),
                  const SizedBox(height: 18),
                  for (final item
                      in OfficialSyllabusData.executiveOverview) ...[
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(item.parameter, color: a.accent),
                          const SizedBox(height: 12),
                          row('APSSB', item.apssb),
                          Divider(color: a.hairline, height: 22),
                          row('APPSC', item.appsc),
                          if (item.note != null) ...[
                            const SizedBox(height: 12),
                            Text(item.note!,
                                style: AuraType.sans(12.5, a.review,
                                    weight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
