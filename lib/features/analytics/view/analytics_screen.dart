import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../exam/data/attempt.dart';
import '../../learn/data/learn_deck.dart';
import '../../learn/data/topic_mapping.dart';
import '../../shell/view/app_shell.dart';

class SubjectStat {
  final String subject;
  final int correct;
  final int attempted;
  const SubjectStat(this.subject, this.correct, this.attempted);
  double get accuracy => attempted == 0 ? 0 : correct / attempted;
}

/// Per-subject accuracy across all attempts, weakest first.
List<SubjectStat> subjectStats(List<Attempt> attempts) {
  final correct = <String, int>{};
  final attempted = <String, int>{};
  for (final t in attempts) {
    for (final q in t.questions) {
      final sel = t.selected[q.id];
      if (sel == null || !q.hasAnswerKey) continue;
      final s = q.subject.trim().isEmpty ? 'General' : q.subject.trim();
      attempted[s] = (attempted[s] ?? 0) + 1;
      if (sel == q.correctAnswer) correct[s] = (correct[s] ?? 0) + 1;
    }
  }
  return attempted.entries
      .where((e) => e.value >= 3)
      .map((e) => SubjectStat(e.key, correct[e.key] ?? 0, e.value))
      .toList()
    ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? _cacheKey;
  List<Attempt> _attempts = const [];

  List<Attempt> _load() {
    final history = ref.read(storageServiceProvider).getQuizHistory();
    final key =
        '${history.length}:${history.isEmpty ? 0 : history.first.hashCode}';
    if (key != _cacheKey) {
      _cacheKey = key;
      _attempts = loadAttempts(ref.read(storageServiceProvider));
    }
    return _attempts;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentTabProvider); // reload when the tab is shown
    final a = context.aura;
    final attempts = _load();
    final graded = attempts.where((t) => t.maxScore > 0).toList();
    final correct = attempts.fold<int>(0, (s, t) => s + t.correct);
    final tried = attempts.fold<int>(0, (s, t) => s + t.attempted);
    final avgScore = graded.isEmpty
        ? null
        : graded.fold<double>(0, (s, t) => s + t.scoreRatio) / graded.length;
    final trend = graded.take(12).toList().reversed.toList();
    final subjects = subjectStats(attempts);
    final weakFocus = findWeakTopics(attempts, max: 3);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: ChromeHeader(
            title: 'Performance',
            subtitle: attempts.isEmpty
                ? 'Your scores and weak subjects'
                : '${attempts.length} ${attempts.length == 1 ? 'test' : 'tests'} taken',
            actions: [
              IconButton(
                tooltip: 'Account & settings',
                onPressed: () => context.push('/account'),
                icon: Icon(CupertinoIcons.gear, color: a.ink, size: 22),
              ),
            ],
          ),
        ),
        if (attempts.isEmpty)
          SliverToBoxAdapter(
            child: AuraEmpty(
              icon: CupertinoIcons.chart_bar,
              title: 'Your progress lives here',
              message:
                  'Finish a paper or mock test and your scores, accuracy and weak subjects appear here.',
              actionLabel: 'Take a mock test',
              onAction: () => ref.read(currentTabProvider.notifier).state = 2,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AuraSpace.gutter, 18, AuraSpace.gutter, 0),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    _Tile(value: '${attempts.length}', label: 'Tests taken'),
                    const SizedBox(width: 10),
                    _Tile(
                        value: avgScore == null
                            ? '—'
                            : '${(avgScore * 100).round()}%',
                        label: 'Avg score'),
                    const SizedBox(width: 10),
                    _Tile(
                        value: tried == 0
                            ? '—'
                            : '${(correct / tried * 100).round()}%',
                        label: 'Accuracy'),
                  ],
                ),
                if (trend.length >= 2) ...[
                  const SizedBox(height: 30),
                  const SectionHeader('Score trend'),
                  Text(
                      'Score as % of maximum, last ${trend.length} scored tests',
                      style: AuraType.sans(12.5, a.inkFaint)),
                  const SizedBox(height: 14),
                  GlassCard(
                    padding: const EdgeInsets.fromLTRB(14, 18, 18, 12),
                    child: SizedBox(
                      height: 170,
                      child: _TrendChart(
                          values: [for (final t in trend) t.scoreRatio]),
                    ),
                  ),
                ],
                if (weakFocus.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  const SectionHeader('Focus on'),
                  Text('Weakest subjects from your completed papers',
                      style: AuraType.sans(12.5, a.inkFaint)),
                  const SizedBox(height: 14),
                  for (final weak in weakFocus) ...[
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  weak.topic.label,
                                  style: AuraType.sans(15, a.ink,
                                      weight: FontWeight.w600),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${weak.subject}: ${weak.accuracyPercent}%, ${weak.correct} of ${weak.attempted} correct',
                                  style: AuraType.sans(13, a.inkMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                            onPressed: () => context.push(
                                '/learn?topic=${weak.topic.name}&limit=10'),
                            child: const Text('Practise 10 cards'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
                if (subjects.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  const SectionHeader('By subject'),
                  Text('Accuracy on answered questions, weakest first',
                      style: AuraType.sans(12.5, a.inkFaint)),
                  const SizedBox(height: 14),
                  GlassCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < subjects.length && i < 8; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          _SubjectBar(
                              stat: subjects[i],
                              focus: i == 0 && subjects.length > 1),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                SectionHeader('Recent tests',
                    actionLabel: attempts.length > 5 ? 'See all' : null,
                    onAction: () => context.push('/quiz-history')),
                const SizedBox(height: 6),
                for (final t in attempts.take(5)) ...[
                  AttemptRow(attempt: t),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        SliverToBoxAdapter(
            child:
                SizedBox(height: 110 + MediaQuery.paddingOf(context).bottom)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String value;
  final String label;
  const _Tile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: AuraType.digits(26, a.ink, weight: FontWeight.w300)),
            ),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuraType.sans(12, a.inkFaint)),
          ],
        ),
      ),
    );
  }
}

class _SubjectBar extends StatelessWidget {
  final SubjectStat stat;
  final bool focus;
  const _SubjectBar({required this.stat, required this.focus});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(stat.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuraType.sans(14, a.ink, weight: FontWeight.w500)),
            ),
            if (focus) ...[
              Tag('Focus area', color: a.review),
              const SizedBox(width: 10)
            ],
            Text('${(stat.accuracy * 100).round()}%',
                style: AuraType.digits(14, a.ink)),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (_, c) => Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                    color: a.hairline, borderRadius: BorderRadius.circular(99)),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: stat.accuracy),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Container(
                  height: 6,
                  width: c.maxWidth * v,
                  decoration: BoxDecoration(
                      color: a.accent, borderRadius: BorderRadius.circular(99)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('${stat.correct} of ${stat.attempted} correct',
            style: AuraType.sans(11.5, a.inkFaint)),
      ],
    );
  }
}

class AttemptRow extends StatelessWidget {
  final Attempt attempt;
  const AttemptRow({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final t = attempt;
    String fmt(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return GlassCard(
      onTap: () => context.push('/mock-test-result', extra: t.raw),
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AuraType.sans(14.5, a.ink, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                MetaLine([t.date, t.mode == 'study' ? 'Study' : null]),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(t.maxScore > 0 ? '${fmt(t.score)}/${fmt(t.maxScore)}' : '—',
                  style: AuraType.digits(14.5, a.ink)),
              const SizedBox(height: 3),
              Text('${(t.accuracy * 100).round()}% acc.',
                  style: AuraType.sans(11.5, a.inkFaint)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single-series line, 0–100%. Tap or drag to read any point.
class _TrendChart extends StatefulWidget {
  final List<double> values; // 0..1, oldest first
  const _TrendChart({required this.values});

  @override
  State<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<_TrendChart> {
  int? _active;

  void _pick(Offset p, Size size) {
    final n = widget.values.length;
    const left = _TrendPainter.leftPad;
    final w = size.width - left - _TrendPainter.rightPad;
    final i = ((p.dx - left) / w * (n - 1)).round().clamp(0, n - 1);
    if (i != _active) setState(() => _active = i);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final last = widget.values.last;
    return LayoutBuilder(builder: (_, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      return Semantics(
        label: 'Score trend. Latest ${(last * 100).round()} percent.',
        child: GestureDetector(
          onTapDown: (d) => _pick(d.localPosition, size),
          onHorizontalDragUpdate: (d) => _pick(d.localPosition, size),
          onHorizontalDragEnd: (_) => setState(() => _active = null),
          onTapUp: (_) => Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _active = null);
          }),
          child: CustomPaint(
            size: size,
            painter: _TrendPainter(
              values: widget.values,
              active: _active,
              line: a.accent,
              grid: a.hairline,
              ring: a.surfaceSolid,
              text: a.inkFaint,
              label: a.ink,
            ),
          ),
        ),
      );
    });
  }
}

class _TrendPainter extends CustomPainter {
  static const leftPad = 34.0;
  static const rightPad = 6.0;
  static const topPad = 22.0;
  static const bottomPad = 8.0;

  final List<double> values;
  final int? active;
  final Color line, grid, ring, text, label;

  _TrendPainter({
    required this.values,
    required this.active,
    required this.line,
    required this.grid,
    required this.ring,
    required this.text,
    required this.label,
  });

  void _text(Canvas c, String s, Offset at, Color color, double size,
      {bool alignRight = false,
      bool center = false,
      FontWeight weight = FontWeight.w400}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: weight,
              fontFeatures: const [FontFeature.tabularFigures()])),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = at.dx;
    if (alignRight) dx -= tp.width;
    if (center) dx -= tp.width / 2;
    tp.paint(c, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - leftPad - rightPad;
    final h = size.height - topPad - bottomPad;
    Offset pt(int i) => Offset(
          leftPad + (values.length == 1 ? w / 2 : w * i / (values.length - 1)),
          topPad + h * (1 - values[i].clamp(0.0, 1.0)),
        );

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final v in [0.0, 0.5, 1.0]) {
      final y = topPad + h * (1 - v);
      canvas.drawLine(
          Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
      _text(canvas, '${(v * 100).round()}%', Offset(leftPad - 8, y), text, 10.5,
          alignRight: true);
    }

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (int i = 1; i < values.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    final area = Path.from(path)
      ..lineTo(pt(values.length - 1).dx, topPad + h)
      ..lineTo(pt(0).dx, topPad + h)
      ..close();
    canvas.drawPath(area, Paint()..color = line.withValues(alpha: 0.10));
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    void dot(int i) {
      canvas.drawCircle(pt(i), 6, Paint()..color = ring);
      canvas.drawCircle(pt(i), 4, Paint()..color = line);
    }

    final i = active ?? values.length - 1;
    if (active != null) {
      canvas.drawLine(
          Offset(pt(i).dx, topPad), Offset(pt(i).dx, topPad + h), gridPaint);
    }
    dot(i);
    final p = pt(i);
    final labelX =
        p.dx.clamp(leftPad + 16, size.width - rightPad - 16).toDouble();
    _text(canvas, '${(values[i] * 100).round()}%',
        Offset(labelX, (p.dy - 14).clamp(8, size.height)), label, 12,
        center: true, weight: FontWeight.w600);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.values != values || old.active != active || old.line != line;
}
