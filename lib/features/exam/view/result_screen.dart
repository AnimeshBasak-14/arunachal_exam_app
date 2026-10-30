import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/question_repository.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/math_utils.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../learn/data/learn_deck.dart';
import '../data/attempt.dart';
import '../data/result_comparison.dart';
import 'question_view.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final Attempt attempt;
  final List<Attempt>? history;
  const ResultScreen({super.key, required this.attempt, this.history});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  int _filter = 0; // 0 all · 1 incorrect · 2 skipped
  final _scrollController = ScrollController();

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  String _duration(int s) {
    if (s <= 0) return '—';
    final m = s ~/ 60, sec = s % 60;
    return m >= 60
        ? '${m ~/ 60}h ${m % 60}m'
        : '${m}m ${sec.toString().padLeft(2, '0')}s';
  }

  String _status(Question q) {
    final sel = widget.attempt.selected[q.id];
    if (!q.hasAnswerKey) return 'ungraded';
    if (sel == null) return 'skipped';
    return sel == q.correctAnswer ? 'correct' : 'wrong';
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final t = widget.attempt;
    final qs = t.questions;
    final history =
        widget.history ?? loadAttempts(ref.watch(storageServiceProvider));
    final comparison = compare(t, history);

    final filtered = [
      for (int i = 0; i < qs.length; i++)
        if (_filter == 0 ||
            (_filter == 1 && _status(qs[i]) == 'wrong') ||
            (_filter == 2 && _status(qs[i]) == 'skipped'))
          i,
    ];

    Color deltaColor;
    if (comparison.isFirstAttempt || comparison.previous == null) {
      deltaColor = a.inkMuted;
    } else if (comparison.deltaPoints! > 0) {
      deltaColor = a.success;
    } else if (comparison.deltaPoints! < 0) {
      deltaColor = a.review;
    } else {
      deltaColor = a.inkMuted;
    }

    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _close,
                        icon:
                            Icon(CupertinoIcons.xmark, size: 20, color: a.ink),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AuraSpace.gutter, 8, AuraSpace.gutter, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow(t.mode == 'study' ? 'Study session' : 'Result'),
                      const SizedBox(height: 8),
                      Text(t.title,
                          style: AuraType.serif(26, a.ink, height: 1.2)),
                      const SizedBox(height: 22),

                      // Main anchor block
                      GlassCard(
                        elevated: true,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      t.maxScore > 0
                                          ? '${(t.scoreRatio * 100).round()}%'
                                          : _fmt(t.score),
                                      style: AuraType.digits(52, a.ink,
                                          weight: FontWeight.w300),
                                    ),
                                  ),
                                ),
                                if (t.maxScore > 0) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 10, left: 10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          _fmt(t.score),
                                          style: AuraType.digits(18, a.inkMuted,
                                              weight: FontWeight.w500),
                                        ),
                                        Text(
                                          '/ ${_fmt(t.maxScore)}',
                                          style: AuraType.digits(15, a.inkFaint,
                                              weight: FontWeight.w400),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (comparison.isPersonalBest) ...[
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Tag('New personal best',
                                        color: a.accent),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comparison.deltaHeadline,
                              style: AuraType.sans(14, deltaColor,
                                  weight: FontWeight.w500),
                            ),
                            if (comparison.deltaSubline != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                comparison.deltaSubline!,
                                style: AuraType.sans(12.5, a.inkMuted),
                              ),
                            ],
                            if (comparison.recentAttempts.length >= 2) ...[
                              const SizedBox(height: 18),
                              _SparklineRow(
                                  attempts: comparison.recentAttempts),
                            ],
                            const SizedBox(height: 18),
                            _ProportionBar(
                              correct: t.correct,
                              wrong: t.wrong,
                              left: t.left + t.ungraded,
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 18,
                              runSpacing: 6,
                              children: [
                                _Key(
                                    color: a.accent,
                                    label: 'Correct',
                                    value: t.correct),
                                _Key(
                                    color: a.danger,
                                    label: 'Wrong',
                                    value: t.wrong),
                                _Key(
                                    color: a.hairline,
                                    label: 'Skipped',
                                    value: t.left),
                                if (t.ungraded > 0)
                                  _Key(
                                      color: a.review,
                                      label: 'Key pending',
                                      value: t.ungraded),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _Stat(
                              label: 'Accuracy',
                              value: '${(t.accuracy * 100).round()}%'),
                          const SizedBox(width: 10),
                          _Stat(
                              label: 'Time taken',
                              value: _duration(t.timeTaken)),
                          const SizedBox(width: 10),
                          _Stat(
                              label: 'Attempted',
                              value:
                                  '${t.attempted}/${t.questions.isEmpty ? t.attempted + t.left : t.questions.length}'),
                        ],
                      ),
                      if (t.mode != 'study' &&
                          t.newRating != null &&
                          t.maxScore > 0) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Rating ${t.newRating}  (${t.ratingChange + t.speedBonus >= 0 ? '+' : ''}${t.ratingChange + t.speedBonus})',
                          style: AuraType.sans(12.5, a.inkFaint),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Primary action button: Practise weak topic or review mistakes
                      if (comparison.weakTopic != null)
                        FilledButton(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52)),
                          onPressed: () => context.push(
                              '/learn?topic=${comparison.weakTopic!.topic.name}&limit=10'),
                          child: Text(
                              'Practise your weak topics (${comparison.weakTopic!.topic.label})'),
                        )
                      else if (qs.isNotEmpty)
                        FilledButton(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52)),
                          onPressed: () {
                            setState(() => _filter = 1);
                            _scrollController.animateTo(
                              380,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                          child: const Text('Review mistakes'),
                        ),

                      if (qs.isNotEmpty) ...[
                        const SizedBox(height: 30),
                        const SectionHeader('Review answers'),
                        SegmentedTabs(
                          labels: const ['All', 'Incorrect', 'Skipped'],
                          selected: _filter,
                          onChanged: (i) => setState(() => _filter = i),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
              if (qs.isNotEmpty && filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _filter == 1
                          ? 'No incorrect answers. Well done.'
                          : 'You answered every question.',
                      textAlign: TextAlign.center,
                      style: AuraType.sans(14, a.inkMuted),
                    ),
                  ),
                ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AuraSpace.gutter),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final idx = filtered[i];
                    return _ReviewTile(
                      number: idx + 1,
                      question: qs[idx],
                      selected: t.selected[qs[idx].id],
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      AuraSpace.gutter,
                      24,
                      AuraSpace.gutter,
                      24 + MediaQuery.paddingOf(context).bottom),
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    child: const Text('Back to dashboard'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini bar sparkline showing up to the last 5 attempts in chronological order.
class _SparklineRow extends StatelessWidget {
  final List<Attempt> attempts;
  const _SparklineRow({required this.attempts});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last ${attempts.length} attempts',
          style: AuraType.sans(11.5, a.inkFaint),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < attempts.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _MiniBar(
                  ratio: attempts[i].scoreRatio,
                  isCurrent: i == attempts.length - 1,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double ratio;
  final bool isCurrent;
  const _MiniBar({required this.ratio, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final clamped = ratio.clamp(0.08, 1.0);
    return Tooltip(
      message: '${(ratio * 100).round()}%',
      child: Container(
        width: 28,
        height: 38,
        alignment: Alignment.bottomCenter,
        decoration: BoxDecoration(
          color: a.hairline.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: FractionallySizedBox(
          heightFactor: clamped,
          child: Container(
            decoration: BoxDecoration(
              color: isCurrent ? a.accent : a.inkMuted.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProportionBar extends StatelessWidget {
  final int correct, wrong, left;
  const _ProportionBar(
      {required this.correct, required this.wrong, required this.left});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final total = correct + wrong + left;
    if (total == 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            if (correct > 0)
              Expanded(flex: correct, child: ColoredBox(color: a.accent)),
            if (wrong > 0)
              Expanded(flex: wrong, child: ColoredBox(color: a.danger)),
            if (left > 0)
              Expanded(flex: left, child: ColoredBox(color: a.hairline)),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  const _Key({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ', style: AuraType.sans(12.5, a.inkMuted)),
        Text('$value', style: AuraType.digits(12.5, a.ink)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        radius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AuraType.digits(17, a.ink)),
            ),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuraType.sans(11.5, a.inkFaint)),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatefulWidget {
  final int number;
  final Question question;
  final String? selected;
  const _ReviewTile(
      {required this.number, required this.question, this.selected});

  @override
  State<_ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends State<_ReviewTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final q = widget.question;
    final opts = {
      for (final o in ParsedOption.parse(q.options)) o.letter: o.text
    };
    final sel = widget.selected;
    final (String label, Color color) = !q.hasAnswerKey
        ? ('Key pending', a.review)
        : sel == null
            ? ('Skipped', a.inkFaint)
            : sel == q.correctAnswer
                ? ('Correct', a.accent)
                : ('Incorrect', a.danger);

    Widget answerLine(String prefix, String? letter, Color c) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: '$prefix  ', style: AuraType.sans(12.5, a.inkFaint)),
              TextSpan(
                text: letter == null
                    ? '—'
                    : '${letter.toUpperCase()}. ${MathUtils.formatMath(opts[letter] ?? '')}',
                style:
                    AuraType.sans(14, c, weight: FontWeight.w500, height: 1.45),
              ),
            ]),
          ),
        );

    return GlassCard(
      onTap: () => setState(() => _open = !_open),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Q${widget.number}',
                  style:
                      AuraType.digits(13, a.inkMuted, weight: FontWeight.w600)),
              const SizedBox(width: 10),
              Tag(label, color: color),
              const Spacer(),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                child: Icon(CupertinoIcons.chevron_down,
                    size: 15, color: a.inkFaint),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            MathUtils.cleanQuestionText(q.questionText, widget.number),
            maxLines: _open ? null : 3,
            overflow: _open ? null : TextOverflow.ellipsis,
            style: AuraType.sans(15, a.ink, height: 1.55),
          ),
          if (sel != null && sel != q.correctAnswer)
            answerLine('Your answer', sel, q.hasAnswerKey ? a.danger : a.ink),
          if (q.hasAnswerKey) answerLine('Correct', q.correctAnswer, a.accent),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _open && q.solution.trim().isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: a.hairline),
                        const SizedBox(height: 12),
                        const Eyebrow('Explanation'),
                        const SizedBox(height: 6),
                        Text(MathUtils.formatMath(q.solution.trim()),
                            style:
                                AuraType.sans(14.5, a.inkMuted, height: 1.6)),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
