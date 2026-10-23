import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../papers/data/paper.dart';
import '../data/live_mock.dart';

/// Elevated "Live Mock Arena" panel with a countdown to the next state-wide
/// mock, then a Begin button while the session is open.
class LiveMockCard extends ConsumerStatefulWidget {
  const LiveMockCard({super.key});

  @override
  ConsumerState<LiveMockCard> createState() => _LiveMockCardState();
}

class _LiveMockCardState extends ConsumerState<LiveMockCard> {
  static const _reminderId = 4201;
  late Timer _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Future<void> _toggleEnrol(LiveMock m, bool enrolled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (enrolled) {
      await prefs.remove(m.enrolKey);
      await NotificationService.cancel(_reminderId);
      if (mounted) setState(() {});
      messenger.showSnackBar(const SnackBar(content: Text('Enrolment cancelled')));
      return;
    }
    await prefs.setBool(m.enrolKey, true);
    final reminded = await NotificationService.scheduleAt(
      id: _reminderId,
      title: '${m.title} starts in 15 minutes',
      body: 'Find a quiet spot. The paper opens at ${m.scheduleLabel}.',
      when: m.start.subtract(const Duration(minutes: 15)),
    );
    if (mounted) setState(() {});
    messenger.showSnackBar(SnackBar(
      content: Text(reminded
          ? "You're enrolled. We'll remind you 15 minutes before it starts."
          : "You're enrolled. Open the app at the start time."),
    ));
  }

  String? _beginRoute(LiveMock m, List<Paper> mocks) {
    if (m.testId != null) {
      return Uri(path: '/mock-test/LIVE/full', queryParameters: {
        'paperType': 'MOCK',
        'testId': m.testId!,
        'duration': '${m.durationMinutes}',
        'title': m.title,
      }).toString();
    }
    return mocks.isEmpty ? null : mocks.first.examRoute(study: false);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final m = LiveMock.resolve(ref.watch(remoteConfigServiceProvider), _now);
    final live = m.isLive(_now);
    final enrolled =
        ref.watch(sharedPreferencesProvider).getBool(m.enrolKey) ?? false;
    final mocks = ref.watch(papersProvider(PaperKind.mock)).value?.papers ??
        const <Paper>[];
    final remaining = (live ? m.end : m.start).difference(_now.toUtc());

    return GlassCard(
      elevated: true,
      borderColor: a.accent.withValues(alpha: 0.28),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PulseDot(color: live ? a.danger : a.accent, pulsing: live),
              const SizedBox(width: 8),
              Expanded(
                child: Eyebrow(live ? 'Live now' : 'Live Mock Arena',
                    color: live ? a.danger : a.accent),
              ),
              Icon(CupertinoIcons.timer, size: 18, color: a.inkFaint),
            ],
          ),
          const SizedBox(height: 14),
          Text(m.title, style: AuraType.serif(24, a.ink, height: 1.2)),
          const SizedBox(height: 6),
          Text(m.scheduleLabel, style: AuraType.sans(13, a.inkMuted)),
          const SizedBox(height: 22),
          Text(live ? 'Session closes in' : 'Starts in',
              style: AuraType.sans(12, a.inkFaint)),
          const SizedBox(height: 8),
          _Countdown(remaining: remaining),
          const SizedBox(height: 22),
          if (live)
            FilledButton(
              onPressed: _beginRoute(m, mocks) == null
                  ? null
                  : () => context.push(_beginRoute(m, mocks)!),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54)),
              child: Text(_beginRoute(m, mocks) == null
                  ? 'Paper not published yet'
                  : 'Begin Test'),
            )
          else if (enrolled)
            OutlinedButton.icon(
              onPressed: () => _toggleEnrol(m, true),
              icon: Icon(CupertinoIcons.checkmark_alt, size: 18, color: a.accent),
              label: const Text("You're enrolled"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                side: BorderSide(color: a.accent.withValues(alpha: 0.4)),
              ),
            )
          else
            FilledButton(
              onPressed: () => _toggleEnrol(m, false),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54)),
              child: const Text('Enroll in Mock'),
            ),
        ],
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  final Duration remaining;
  const _Countdown({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final r = remaining.isNegative ? Duration.zero : remaining;
    final units = [
      (r.inDays, 'days'),
      (r.inHours % 24, 'hrs'),
      (r.inMinutes % 60, 'min'),
      (r.inSeconds % 60, 'sec'),
    ];
    return Row(
      children: [
        for (int i = 0; i < units.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(':', style: AuraType.digits(22, a.inkFaint, weight: FontWeight.w300)),
            ),
          Expanded(
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    units[i].$1.toString().padLeft(2, '0'),
                    style: AuraType.digits(30, a.ink, weight: FontWeight.w300),
                  ),
                ),
                const SizedBox(height: 2),
                Text(units[i].$2, style: AuraType.sans(11, a.inkFaint)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  final bool pulsing;
  const _PulseDot({required this.color, required this.pulsing});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.pulsing && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.pulsing && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.pulsing
          ? Tween(begin: 0.35, end: 1.0).animate(_c)
          : const AlwaysStoppedAnimation(1),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
