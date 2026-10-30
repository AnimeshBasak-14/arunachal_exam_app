import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../data/official_syllabus_data.dart';
import '../../learn/data/learn_deck.dart';
import '../../streak/data/time_tracker.dart';
import '../../streak/view/coin_widgets.dart';

class SyllabusScreen extends StatefulWidget {
  final int initialTabIndex;
  const SyllabusScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  late int _tab = widget.initialTabIndex.clamp(0, 3);
  String _q = '';

  bool _hit(List<String> fields) {
    final q = _q.trim().toLowerCase();
    return q.isEmpty || fields.any((f) => f.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) => TimeTracked(
        section: 'read',
        sub: 'syllabus',
        child: _buildContent(context),
      );

  Widget _buildContent(BuildContext context) {
    final bottom = 40 + MediaQuery.paddingOf(context).bottom;

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
              title: const Text('Syllabus & pattern'),
              actions: const [HiddenCoin('syllabus'), SizedBox(width: 6)],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AuraSpace.gutter, 0, AuraSpace.gutter, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedTabs(
                      labels: const ['Overview', 'APSSB', 'APPSC', 'Subjects'],
                      selected: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                    if (_tab != 0) ...[
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (v) => setState(() => _q = v),
                        decoration: const InputDecoration(
                          hintText: 'Search exams, papers or topics',
                          prefixIcon: Icon(CupertinoIcons.search, size: 18),
                          isDense: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  AuraSpace.gutter, 8, AuraSpace.gutter, bottom),
              sliver: SliverList.list(
                children: switch (_tab) {
                  0 => _overview(context),
                  1 => _apssb(context),
                  2 => _appsc(context),
                  _ => _subjects(context),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _overview(BuildContext context) {
    final a = context.aura;
    return [
      Text(
          'APSSB recruits Group C posts; APPSC recruits Group A and B. '
          'Their marking rules differ, and that changes how you attempt the paper.',
          style: AuraType.sans(14.5, a.inkMuted, height: 1.55)),
      const SizedBox(height: 18),
      for (final item in OfficialSyllabusData.executiveOverview) ...[
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(item.parameter, color: a.accent),
              const SizedBox(height: 12),
              _compareRow(context, 'APSSB', item.apssb),
              Divider(color: a.hairline, height: 22),
              _compareRow(context, 'APPSC', item.appsc),
              if (item.note != null) ...[
                const SizedBox(height: 12),
                Text(item.note!,
                    style:
                        AuraType.sans(12.5, a.review, weight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _compareRow(BuildContext context, String who, String text) {
    final a = context.aura;
    final isUrl = text.startsWith('http');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  List<Widget> _apssb(BuildContext context) {
    final rows = OfficialSyllabusData.apssbSections
        .where((s) =>
            _hit([s.examName, s.subject, s.syllabusBreakdown, s.targetCadres]))
        .toList();
    final exams = <String, List<ApssbSyllabusSection>>{};
    for (final s in rows) {
      exams.putIfAbsent(s.examName, () => []).add(s);
    }
    if (exams.isEmpty) return [_none(context)];
    return [
      for (final e in exams.entries) ...[
        _ExamCard(
          title: e.key,
          subtitle: e.value.first.targetCadres,
          meta: [
            '${e.value.fold<int>(0, (t, s) => t + (s.marks ?? 0))} marks',
            e.value.first.markingStandard.split(';').first,
          ],
          initiallyOpen: _q.isNotEmpty,
          children: [
            for (final s in e.value)
              _PaperRow(
                stage: s.stage,
                title: s.subject,
                meta: [
                  if (s.questions != null) '${s.questions} Qs',
                  if (s.marks != null) '${s.marks} marks',
                  s.duration,
                ],
                body: s.syllabusBreakdown,
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> _appsc(BuildContext context) {
    final a = context.aura;
    final rows = OfficialSyllabusData.appscSections
        .where((s) => _hit([
              s.examName,
              s.paperName,
              s.primaryCurriculum,
              s.arunachalComponent,
              s.targetCadres
            ]))
        .toList();
    final exams = <String, List<AppscSyllabusSection>>{};
    for (final s in rows) {
      exams.putIfAbsent(s.examName, () => []).add(s);
    }
    if (exams.isEmpty) return [_none(context)];
    return [
      for (final e in exams.entries) ...[
        _ExamCard(
          title: e.key,
          subtitle: e.value.first.targetCadres,
          meta: ['${e.value.length} papers'],
          initiallyOpen: _q.isNotEmpty,
          children: [
            for (final s in e.value)
              _PaperRow(
                stage: s.stage,
                title: s.paperName,
                meta: ['${s.marks} marks', s.duration, s.negativeMarking],
                body: s.primaryCurriculum,
                extra: s.arunachalComponent.startsWith('None')
                    ? null
                    : Text('Arunachal focus: ${s.arunachalComponent}',
                        style: AuraType.sans(13.5, a.accent, height: 1.5)),
                footnote: s.weightageImpact,
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> _subjects(BuildContext context) {
    final a = context.aura;
    final rows = OfficialSyllabusData.subjectMatrix
        .where((s) =>
            _hit([s.category, s.subTopic, s.coreCurriculum, s.highYieldFocus]))
        .toList();
    if (rows.isEmpty) return [_none(context)];
    final groups = <String, List<SubjectMatrixItem>>{};
    for (final s in rows) {
      groups.putIfAbsent(s.category, () => []).add(s);
    }
    return [
      for (final g in groups.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Text(g.key, style: AuraType.serif(20, a.ink)),
        ),
        for (final s in g.value) ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.subTopic,
                    style: AuraType.sans(16, a.ink, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(s.typicalWeightage,
                    style: AuraType.sans(12.5, a.inkFaint)),
                const SizedBox(height: 10),
                Text(s.coreCurriculum,
                    style: AuraType.sans(14, a.inkMuted, height: 1.55)),
                const SizedBox(height: 12),
                _compareRow(context, 'APSSB', s.apssbScope),
                const SizedBox(height: 8),
                _compareRow(context, 'APPSC', s.appscScope),
                const SizedBox(height: 12),
                Row(children: [
                  Icon(CupertinoIcons.star, size: 14, color: a.review),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(s.highYieldFocus,
                          style: AuraType.sans(13, a.review,
                              weight: FontWeight.w500))),
                ]),
                if (_topicFor(s) case final t?) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => context.push('/learn?topic=${t.name}'),
                    icon: const Icon(CupertinoIcons.play_fill, size: 14),
                    label: Text('Practise ${t.label}'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    ];
  }

  LearnTopic? _topicFor(SubjectMatrixItem s) {
    final t = '${s.category} ${s.subTopic}'.toLowerCase();
    if (t.contains('arunachal')) return LearnTopic.arunachal;
    if (t.contains('english') || t.contains('grammar')) {
      return LearnTopic.grammar;
    }
    if (t.contains('polity') || t.contains('constitution')) {
      return LearnTopic.polity;
    }
    if (t.contains('history')) return LearnTopic.history;
    if (t.contains('geograph')) return LearnTopic.geography;
    if (t.contains('econom')) return LearnTopic.economy;
    if (t.contains('environment') || t.contains('ecology')) {
      return LearnTopic.environment;
    }
    if (t.contains('science')) return LearnTopic.science;
    return null;
  }

  Widget _none(BuildContext context) => const AuraEmpty(
        icon: CupertinoIcons.search,
        title: 'No matches',
        message: 'Try a shorter word, like "English" or "Prelims".',
      );
}

class _ExamCard extends StatefulWidget {
  final String title, subtitle;
  final List<String> meta;
  final List<Widget> children;
  final bool initiallyOpen;
  const _ExamCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.children,
    this.initiallyOpen = false,
  });

  @override
  State<_ExamCard> createState() => _ExamCardState();
}

class _ExamCardState extends State<_ExamCard> {
  late bool _open = widget.initiallyOpen;

  @override
  void didUpdateWidget(covariant _ExamCard old) {
    super.didUpdateWidget(old);
    if (widget.initiallyOpen && !old.initiallyOpen) _open = true;
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AuraSpace.radius),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AuraType.serif(18, a.ink)),
                        const SizedBox(height: 4),
                        Text(widget.subtitle,
                            maxLines: _open ? 4 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: AuraType.sans(13, a.inkMuted)),
                        const SizedBox(height: 6),
                        MetaLine(widget.meta, color: a.inkFaint),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(CupertinoIcons.chevron_down,
                        size: 16, color: a.inkFaint),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: _open
                ? Column(children: [
                    for (final c in widget.children) ...[
                      Divider(color: a.hairline),
                      c
                    ],
                  ])
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _PaperRow extends StatelessWidget {
  final String stage, title, body;
  final List<String> meta;
  final Widget? extra;
  final String? footnote;
  const _PaperRow({
    required this.stage,
    required this.title,
    required this.meta,
    required this.body,
    this.extra,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(stage),
          const SizedBox(height: 4),
          Text(title,
              style: AuraType.sans(15.5, a.ink, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final m in meta) Tag(m)]),
          const SizedBox(height: 10),
          Text(body, style: AuraType.sans(14, a.inkMuted, height: 1.55)),
          if (extra != null) ...[const SizedBox(height: 8), extra!],
          if (footnote != null) ...[
            const SizedBox(height: 8),
            Text(footnote!,
                style: AuraType.sans(12.5, a.inkFaint, height: 1.45)),
          ],
        ],
      ),
    );
  }
}
