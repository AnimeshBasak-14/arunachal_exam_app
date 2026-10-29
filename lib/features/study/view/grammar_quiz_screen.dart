import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../learn/data/learn_deck.dart';

/// Timed English test: 15 random grammar and vocabulary questions, 30
/// seconds each. Results are saved to test history.
class GrammarQuizScreen extends ConsumerStatefulWidget {
  const GrammarQuizScreen({super.key});

  @override
  ConsumerState<GrammarQuizScreen> createState() => _GrammarQuizScreenState();
}

class _GrammarQuizScreenState extends ConsumerState<GrammarQuizScreen> {
  static const _count = 15;
  static const _perQuestion = 30;

  late List<LearnCard> _qs;
  final _picked = <int, int>{}; // question index -> option (-1 = timed out)
  int _i = 0;
  int _left = _perQuestion;
  Timer? _timer;
  final _started = DateTime.now();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final pool = [
      ...learnDeck[LearnTopic.grammar]!,
      ...learnDeck[LearnTopic.vocab]!,
    ].where((c) => c.kind == CardKind.quiz).toList()
      ..shuffle(math.Random());
    _qs = pool.take(_count).toList();
    _picked.clear();
    _i = 0;
    _done = false;
    _tick();
  }

  void _tick() {
    _timer?.cancel();
    _left = _perQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left <= 1) {
        t.cancel();
        _answer(-1);
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _answer(int option) {
    if (_picked.containsKey(_i)) return;
    _timer?.cancel();
    final right = option == _qs[_i].answer;
    right ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
    setState(() => _picked[_i] = option);
  }

  void _next() {
    if (_i + 1 >= _qs.length) {
      _finish();
    } else {
      setState(() => _i++);
      _tick();
    }
  }

  int get _score => [
        for (int i = 0; i < _qs.length; i++)
          if (_picked[i] == _qs[i].answer) 1
      ].length;

  Future<void> _finish() async {
    setState(() => _done = true);
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final date =
        '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}';
    final answered = _picked.values.where((v) => v >= 0).length;
    final record = {
      'examCode': 'ENGLISH',
      'testTitle': 'Timed English test',
      'mode': 'exam',
      'score': _score,
      'maxScore': _qs.length,
      'ratingChange': 0,
      'speedBonus': 0,
      'correct': _score,
      'wrong': answered - _score,
      'left': _qs.length - answered,
      'ungraded': 0,
      'timeTaken': now.difference(_started).inSeconds,
      'date': date,
      'completedAt': date,
    };
    final storage = ref.read(storageServiceProvider);
    StreakService(ref.read(sharedPreferencesProvider)).checkAndUpdateStreak();
    await storage
        .saveQuizHistory([jsonEncode(record), ...storage.getQuizHistory()]);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return AuraBackground(
      child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Close',
              icon: const Icon(CupertinoIcons.xmark),
              onPressed: () => context.pop(),
            ),
            title:
                Text(_done ? 'Result' : 'Question ${_i + 1} of ${_qs.length}'),
            actions: [
              if (!_done)
                Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Center(
                    child: Text('0:${_left.toString().padLeft(2, '0')}',
                        style: AuraType.digits(
                            16, _left <= 5 ? a.danger : a.inkMuted,
                            weight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          body: SafeArea(
              top: false,
              child: _done ? _result(context) : _question(context))),
    );
  }

  Widget _question(BuildContext context) {
    final a = context.aura;
    final q = _qs[_i];
    final picked = _picked[_i];
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(AuraSpace.gutter, 4, AuraSpace.gutter, 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
              value: (_i + (picked != null ? 1 : 0)) / _qs.length,
              minHeight: 4),
        ),
        const SizedBox(height: 24),
        Eyebrow(q.eyebrow),
        const SizedBox(height: 10),
        Text(q.prompt,
            style: AuraType.serif(q.prompt.length > 90 ? 20 : 24, a.ink,
                height: 1.3)),
        const SizedBox(height: 22),
        for (int o = 0; o < q.options.length; o++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Option(
              text: q.options[o],
              color: picked == null
                  ? null
                  : o == q.answer
                      ? a.success
                      : o == picked
                          ? a.danger
                          : a.hairline,
              onTap: picked == null ? () => _answer(o) : null,
            ),
          ),
        if (picked != null) ...[
          const SizedBox(height: 6),
          Text(
            picked == q.answer
                ? 'Correct'
                : (picked < 0 ? 'Time\'s up' : 'Not quite'),
            style: AuraType.sans(14, picked == q.answer ? a.success : a.danger,
                weight: FontWeight.w600),
          ),
          if (q.explain != null) ...[
            const SizedBox(height: 6),
            Text(q.explain!,
                style: AuraType.sans(14.5, a.inkMuted, height: 1.5)),
          ],
          const SizedBox(height: 20),
          FilledButton(
              onPressed: _next,
              child:
                  Text(_i + 1 >= _qs.length ? 'See result' : 'Next question')),
        ],
      ],
    );
  }

  Widget _result(BuildContext context) {
    final a = context.aura;
    final pct = (_score / _qs.length * 100).round();
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(AuraSpace.gutter, 8, AuraSpace.gutter, 32),
      children: [
        Text('$_score / ${_qs.length}', style: AuraType.serif(48, a.ink)),
        Text(
            pct >= 80
                ? 'Excellent work.'
                : pct >= 50
                    ? 'Good. Review the misses below.'
                    : 'Keep practising, this improves fast.',
            style: AuraType.sans(15, a.inkMuted)),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(
              child: OutlinedButton(
                  onPressed: () => context.pop(), child: const Text('Done'))),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
                onPressed: () => setState(_start),
                child: const Text('New test')),
          ),
        ]),
        const SizedBox(height: 28),
        const SectionHeader('Review'),
        const SizedBox(height: 10),
        for (int i = 0; i < _qs.length; i++) ...[
          GlassCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                    _picked[i] == _qs[i].answer
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.xmark_circle_fill,
                    size: 18,
                    color: _picked[i] == _qs[i].answer ? a.success : a.danger),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_qs[i].prompt,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AuraType.sans(14.5, a.ink,
                            weight: FontWeight.w500))),
              ]),
              const SizedBox(height: 6),
              Text('Answer: ${_qs[i].options[_qs[i].answer]}',
                  style: AuraType.sans(13.5, a.inkMuted, height: 1.45)),
            ]),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final String text;
  final Color? color;
  final VoidCallback? onTap;
  const _Option({required this.text, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final c = color;
    return Material(
      color: c == null
          ? a.surface
          : c.withValues(alpha: c == a.hairline ? 0 : 0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AuraSpace.radiusS),
        side: BorderSide(
            color: c ?? a.hairline,
            width: c == null || c == a.hairline ? 0.8 : 1.6),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AuraSpace.radiusS),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(text, style: AuraType.sans(15, a.ink, height: 1.4)),
        ),
      ),
    );
  }
}
