import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../data/learn_deck.dart';
import '../data/learn_progress.dart';

/// Full-screen, swipe-up study feed. Short cards, instant feedback, and
/// missed questions come back a few cards later (spaced retrieval), so the
/// "one more swipe" habit turns into revision.
class LearnFeedScreen extends ConsumerStatefulWidget {
  /// Topics to start with; empty means everything ("For you").
  final Set<LearnTopic> topics;
  final bool savedOnly;
  const LearnFeedScreen(
      {super.key, this.topics = const {}, this.savedOnly = false});

  @override
  ConsumerState<LearnFeedScreen> createState() => _LearnFeedScreenState();
}

class _LearnFeedScreenState extends ConsumerState<LearnFeedScreen> {
  final _pager = PageController();
  late Set<LearnTopic> _topics = widget.topics;
  late List<LearnCard> _feed;
  int _page = 0;
  final _done = <int>{}; // feed positions already scored
  String? _toast;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  void _rebuild() {
    final day = DateTime.now();
    final seed = day.year * 1000 + day.month * 40 + day.day;
    var feed = buildFeed(_topics.isEmpty ? LearnTopic.values.toSet() : _topics,
        seed: seed);
    if (widget.savedOnly) {
      final saved = ref.read(learnProgressProvider).saved;
      feed = feed.where((c) => saved.contains(c.id)).toList();
    } else {
      // Cards already answered right go to the back of the feed.
      final known = ref.read(learnProgressProvider).known;
      feed = [
        ...feed.where((c) => !known.contains(c.id)),
        ...feed.where((c) => known.contains(c.id))
      ];
    }
    _feed = feed;
    _done.clear();
    _page = 0;
    if (_pager.hasClients) _pager.jumpToPage(0);
  }

  void _selectTopic(LearnTopic? t) {
    HapticFeedback.selectionClick();
    setState(() {
      _topics = t == null ? {} : {t};
      _rebuild();
    });
  }

  /// Called once per card when it is read or answered.
  void _complete(int index, {int xp = 2, bool? correct}) {
    if (!_done.add(index)) return;
    final card = _feed[index];
    final n = ref.read(learnProgressProvider.notifier);
    if (correct != null) {
      n.answered(card.id, correct: correct);
      if (!correct) {
        // Bring it back four cards later.
        setState(() => _feed.insert(math.min(index + 5, _feed.length), card));
      }
    }
    final hitGoal = n.finish(xp: xp);
    final combo = ref.read(learnProgressProvider).combo;
    if (hitGoal) {
      _flash('Daily goal reached · streak updated');
      HapticFeedback.heavyImpact();
    } else if (correct == true && combo >= 3 && combo % 3 == 0) {
      _flash('$combo in a row');
    }
  }

  void _flash(String text) {
    setState(() => _toast = text);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && _toast == text) setState(() => _toast = null);
    });
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final progress = ref.watch(learnProgressProvider);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: AuraBackground(
        child: Stack(
          children: [
            if (_feed.isEmpty)
              Center(
                child: AuraEmpty(
                  icon: CupertinoIcons.bookmark,
                  title:
                      widget.savedOnly ? 'No saved cards yet' : 'Nothing here',
                  message: widget.savedOnly
                      ? 'Double-tap any card in the feed to save it for revision.'
                      : 'Try another topic.',
                ),
              )
            else
              PageView.builder(
                controller: _pager,
                scrollDirection: Axis.vertical,
                itemCount: _feed.length,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  // Swiping past a fact card counts it as read.
                  if (i > _page && _feed[_page].kind == CardKind.fact) {
                    _complete(_page);
                  }
                  setState(() => _page = i);
                },
                itemBuilder: (_, i) => _CardPage(
                  key: ValueKey('$i-${_feed[i].id}'),
                  card: _feed[i],
                  saved: progress.saved.contains(_feed[i].id),
                  onSave: () => ref
                      .read(learnProgressProvider.notifier)
                      .toggleSave(_feed[i].id),
                  onAnswered: (correct) =>
                      _complete(i, xp: correct ? 10 : 1, correct: correct),
                  onFlipped: (knew) =>
                      _complete(i, xp: knew ? 5 : 2, correct: knew),
                ),
              ),

            // Header: back, goal ring, XP, topic chips.
            Positioned(
              top: top + 4,
              left: 8,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(CupertinoIcons.back),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(widget.savedOnly ? 'Saved cards' : 'Learn',
                          style: AuraType.serif(20, a.ink)),
                    ),
                    if (progress.combo >= 2) ...[
                      Icon(CupertinoIcons.flame_fill,
                          size: 16, color: a.review),
                      const SizedBox(width: 3),
                      Text('${progress.combo}',
                          style: AuraType.digits(14, a.review,
                              weight: FontWeight.w600)),
                      const SizedBox(width: 14),
                    ],
                    Text('${progress.xp} XP',
                        style: AuraType.digits(13.5, a.inkMuted)),
                    const SizedBox(width: 12),
                    _GoalRing(done: progress.today, goal: dailyCardGoal),
                  ]),
                  if (!widget.savedOnly)
                    MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.15,
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 8),
                          children: [
                            _TopicChip('For you', _topics.isEmpty,
                                () => _selectTopic(null)),
                            for (final t in LearnTopic.values)
                              _TopicChip(
                                  t.label,
                                  _topics.length == 1 && _topics.contains(t),
                                  () => _selectTopic(t)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (_toast != null)
              Positioned(
                top: top + 96,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                        color: a.ink, borderRadius: BorderRadius.circular(99)),
                    child: Text(_toast!,
                        style:
                            AuraType.sans(13.5, a.bg, weight: FontWeight.w600)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalRing extends StatelessWidget {
  final int done, goal;
  const _GoalRing({required this.done, required this.goal});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final complete = done >= goal;
    return Tooltip(
      message: '$done of $goal cards today',
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: (done / goal).clamp(0, 1).toDouble(),
            strokeWidth: 3,
            backgroundColor: a.hairline,
            color: a.accent,
          ),
          complete
              ? Icon(CupertinoIcons.checkmark, size: 13, color: a.accent)
              : Text('$done',
                  style: AuraType.digits(10, a.ink, weight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TopicChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected ? a.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? a.accent : a.hairline),
          ),
          child: Text(label,
              style: AuraType.sans(12.5, selected ? a.onAccent : a.inkMuted,
                  weight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// One card with the side rail (save, explain, map) and double-tap to save.
class _CardPage extends StatefulWidget {
  final LearnCard card;
  final bool saved;
  final VoidCallback onSave;
  final ValueChanged<bool> onAnswered;
  final ValueChanged<bool> onFlipped;
  const _CardPage({
    super.key,
    required this.card,
    required this.saved,
    required this.onSave,
    required this.onAnswered,
    required this.onFlipped,
  });

  @override
  State<_CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<_CardPage>
    with SingleTickerProviderStateMixin {
  int? _picked;
  bool _flipped = false;
  bool? _knew;
  late final _burst = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _doubleTapSave() {
    if (!widget.saved) widget.onSave();
    HapticFeedback.lightImpact();
    _burst.forward(from: 0);
  }

  void _pick(int i) {
    if (_picked != null) return;
    final right = i == widget.card.answer;
    right ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
    setState(() => _picked = i);
    widget.onAnswered(right);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final c = widget.card;
    final pad = MediaQuery.paddingOf(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _doubleTapSave,
      child: Stack(
        children: [
          Padding(
            padding:
                EdgeInsets.fromLTRB(24, pad.top + 100, 72, pad.bottom + 40),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Tag(c.topic.label, color: a.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c.eyebrow.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AuraType.eyebrow(a.inkFaint)),
                      ),
                    ]),
                    const SizedBox(height: 18),
                    switch (c.kind) {
                      CardKind.fact => _fact(context, c),
                      CardKind.quiz => _quiz(context, c),
                      CardKind.flip => _flip(context, c),
                    },
                  ],
                ),
              ),
            ),
          ),

          // Side rail.
          Positioned(
            right: 12,
            bottom: pad.bottom + 60,
            child: Column(children: [
              _RailButton(
                icon: widget.saved
                    ? CupertinoIcons.bookmark_fill
                    : CupertinoIcons.bookmark,
                label: widget.saved ? 'Saved' : 'Save',
                active: widget.saved,
                onTap: widget.onSave,
              ),
              const SizedBox(height: 18),
              _RailButton(
                icon: CupertinoIcons.sparkles,
                label: 'Explain',
                onTap: () => context.push('/chatbot',
                    extra:
                        'Explain this for my APPSC/APSSB preparation, with one memory trick:\n\n'
                        '${c.prompt}\n${c.body ?? ''}\n'
                        '${c.options.isNotEmpty ? 'Answer: ${c.options[c.answer]}' : ''}'),
              ),
              if (c.place != null) ...[
                const SizedBox(height: 18),
                _RailButton(
                  icon: CupertinoIcons.map,
                  label: 'Map',
                  onTap: () => context.push('/gk-map'),
                ),
              ],
            ]),
          ),

          // Double-tap burst.
          IgnorePointer(
            child: Center(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (_, __) {
                  final t = _burst.value;
                  if (t == 0 || t == 1) return const SizedBox.shrink();
                  return Opacity(
                    opacity: (1 - t).clamp(0, 1),
                    child: Transform.scale(
                      scale: 0.6 +
                          Curves.easeOutBack.transform(math.min(t * 1.6, 1)) *
                              0.8,
                      child: Icon(CupertinoIcons.bookmark_fill,
                          size: 96, color: a.accent),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _promptSize(String s) => s.length < 40
      ? 30
      : s.length < 110
          ? 24
          : s.length < 220
              ? 20
              : 17.5;

  Widget _fact(BuildContext context, LearnCard c) {
    final a = context.aura;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.prompt,
            style: AuraType.serif(_promptSize(c.prompt), a.ink, height: 1.3)),
        if (c.body != null) ...[
          const SizedBox(height: 16),
          for (final line in c.body!.split('\n'))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(line,
                  style: AuraType.sans(16, a.inkMuted, height: 1.55)),
            ),
        ],
        if (c.good != null) ...[
          const SizedBox(height: 14),
          _Example(text: c.good!, good: true),
          const SizedBox(height: 8),
          _Example(text: c.bad!, good: false),
        ],
        if (c.explain != null && c.kind == CardKind.fact) ...[
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(CupertinoIcons.lightbulb, size: 17, color: a.review),
            const SizedBox(width: 8),
            Expanded(
                child: Text(c.explain!,
                    style: AuraType.sans(14, a.inkMuted, height: 1.5))),
          ]),
        ],
        const SizedBox(height: 28),
        Row(children: [
          Icon(CupertinoIcons.chevron_up, size: 14, color: a.inkFaint),
          const SizedBox(width: 6),
          Text('Swipe up · double-tap to save',
              style: AuraType.sans(12, a.inkFaint)),
        ]),
      ],
    );
  }

  Widget _quiz(BuildContext context, LearnCard c) {
    final a = context.aura;
    const good = Color(0xFF2F6B55);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.prompt,
            style: AuraType.serif(_promptSize(c.prompt), a.ink, height: 1.3)),
        const SizedBox(height: 22),
        for (int i = 0; i < c.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Option(
              text: c.options[i],
              state: _picked == null
                  ? _OptState.idle
                  : i == c.answer
                      ? _OptState.right
                      : i == _picked
                          ? _OptState.wrong
                          : _OptState.dim,
              onTap: () => _pick(i),
            ),
          ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: _picked == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _picked == c.answer
                            ? 'Correct · +10 XP'
                            : 'It comes back in a few cards',
                        style: AuraType.sans(
                            13.5, _picked == c.answer ? good : a.danger,
                            weight: FontWeight.w600),
                      ),
                      if (c.explain != null) ...[
                        const SizedBox(height: 6),
                        Text(c.explain!,
                            style:
                                AuraType.sans(14.5, a.inkMuted, height: 1.5)),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _flip(BuildContext context, LearnCard c) {
    final a = context.aura;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _flipped = true);
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            transitionBuilder: (child, anim) => AnimatedBuilder(
              animation: anim,
              child: child,
              builder: (_, child) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX((1 - anim.value) * math.pi / 2),
                child: child,
              ),
            ),
            child: GlassCard(
              key: ValueKey(_flipped),
              elevated: true,
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_flipped ? c.body! : c.prompt,
                        style: AuraType.serif(
                            _promptSize(_flipped ? c.body! : c.prompt),
                            _flipped ? a.accent : a.ink,
                            height: 1.3)),
                    const SizedBox(height: 14),
                    Text(_flipped ? c.prompt : 'Tap to reveal',
                        style: AuraType.sans(13, a.inkFaint)),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_flipped) ...[
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _knew != null
                    ? null
                    : () {
                        setState(() => _knew = false);
                        widget.onFlipped(false);
                      },
                child: const Text('Didn\'t know'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _knew != null
                    ? null
                    : () {
                        setState(() => _knew = true);
                        HapticFeedback.mediumImpact();
                        widget.onFlipped(true);
                      },
                child: const Text('Knew it'),
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

enum _OptState { idle, right, wrong, dim }

class _Option extends StatelessWidget {
  final String text;
  final _OptState state;
  final VoidCallback onTap;
  const _Option({required this.text, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    const good = Color(0xFF2F6B55);
    final (border, fill, ink, icon) = switch (state) {
      _OptState.idle => (a.hairline, a.surface, a.ink, null),
      _OptState.right => (
          good,
          good.withValues(alpha: 0.10),
          a.ink,
          CupertinoIcons.checkmark_circle_fill
        ),
      _OptState.wrong => (
          a.danger,
          a.danger.withValues(alpha: 0.08),
          a.ink,
          CupertinoIcons.xmark_circle_fill
        ),
      _OptState.dim => (a.hairline, Colors.transparent, a.inkFaint, null),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AuraSpace.radiusS),
        border: Border.all(
            color: border, width: state == _OptState.idle ? 0.8 : 1.6),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AuraSpace.radiusS),
          onTap: state == _OptState.idle ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Expanded(
                  child:
                      Text(text, style: AuraType.sans(15, ink, height: 1.4))),
              if (icon != null) ...[
                const SizedBox(width: 10),
                Icon(icon, size: 20, color: border),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _Example extends StatelessWidget {
  final String text;
  final bool good;
  const _Example({required this.text, required this.good});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final c = good ? const Color(0xFF2F6B55) : a.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: c, width: 3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(good ? CupertinoIcons.checkmark : CupertinoIcons.xmark,
            size: 15, color: c),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text, style: AuraType.sans(14.5, a.ink, height: 1.45))),
      ]),
    );
  }
}

class _RailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  const _RailButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.active = false});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Column(children: [
          Icon(icon, size: 26, color: active ? a.accent : a.ink),
          const SizedBox(height: 4),
          Text(label,
              style: AuraType.sans(11, a.inkMuted, weight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
