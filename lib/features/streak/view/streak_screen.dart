import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../learn/data/learn_deck.dart';
import '../../learn/view/study_widgets.dart';
import '../data/coins.dart';
import '../data/daily.dart';
import '../data/day_key.dart';
import '../data/time_tracker.dart';
import 'coin_widgets.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

/// Your streak: calendar, today's daily items, coins, and where your time goes.
class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key});

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _range = 0; // 0 today, 1 last 7 days

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final prefs = ref.watch(sharedPreferencesProvider);
    final streaks = StreakService(prefs);
    final log = ref.watch(dailyLogProvider);
    final coins = ref.watch(coinsProvider);
    final now = DateTime.now();
    final today = dayKey(now);

    final studied = {
      ...streaks.getActiveDatesHistory(),
      ...log.keys,
    };
    // The saved streak number only resets when the app next records study, so
    // show 0 once a full day has been missed.
    final last = parseDayKey(streaks.getLastActiveDate() ?? '');
    final missed = last == null ||
        DateTime(now.year, now.month, now.day).difference(last).inDays > 1;
    final streak = missed ? 0 : streaks.getCurrentStreak();
    final solvedToday = log.containsKey(today);
    final foundToday = hiddenSpotsFor(now)
        .where(
            (s) => ref.read(coinsProvider.notifier).has(hiddenCoinKey(now, s)))
        .length;

    final prefix = '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final activeThisMonth = studied.where((d) => d.startsWith(prefix)).length;

    return StudyPage(
      title: 'Streak',
      track: 'read',
      children: [
        Row(children: [
          _Stat(value: '$streak', label: 'day streak'),
          const SizedBox(width: 10),
          _Stat(value: '${streaks.getLongestStreak()}', label: 'best streak'),
          const SizedBox(width: 10),
          _Stat(value: '${coins.balance}', label: 'coins', coin: true),
        ]),
        const SizedBox(height: 26),
        _CalendarCard(
          month: _month,
          studied: studied,
          solved: log.keys.toSet(),
          activeCount: activeThisMonth,
          onPrev: DateTime(_month.year, _month.month - 1)
                  .isBefore(DateTime(now.year - 1, now.month))
              ? null
              : () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1)),
          onNext: _month.year == now.year && _month.month == now.month
              ? null
              : () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1)),
          onDay: (d) => context.push('/daily/${dayKey(d)}'),
        ),
        const SizedBox(height: 30),
        const SectionHeader('Today'),
        const SizedBox(height: 12),
        GlassList(children: [
          GlassListRow(
            icon: CupertinoIcons.question_circle,
            title: 'PYQ of the day',
            subtitle: solvedToday
                ? (log[today]!.correct
                    ? 'Solved. Nice work.'
                    : 'Attempted. Review the answer.')
                : 'One real exam question. Keeps your streak.',
            onTap: () => context.push('/daily/$today'),
          ),
          _MockOfTheDay(date: today),
        ]),
        const SizedBox(height: 10),
        Text(
          'Hidden coins today: $foundToday of 3 found. They sit quietly on some screens.',
          style: AuraType.sans(12.5, a.inkFaint, height: 1.45),
        ),
        const SizedBox(height: 30),
        const SectionHeader('Where your time goes'),
        const SizedBox(height: 10),
        SegmentedTabs(
          labels: const ['Today', 'Last 7 days'],
          selected: _range,
          onChanged: (i) => setState(() => _range = i),
        ),
        const SizedBox(height: 12),
        _TimeCard(
            data: ref.watch(timeTrackerProvider).lastDays(_range == 0 ? 1 : 7)),
        const SizedBox(height: 30),
        const SectionHeader('Coins'),
        const SizedBox(height: 12),
        _CoinsCard(state: coins),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final bool coin;
  const _Stat({required this.value, required this.label, this.coin = false});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 10, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: AuraType.digits(28, a.ink, weight: FontWeight.w300)),
              ),
            ),
            if (coin) ...[const SizedBox(width: 6), const CoinMark(size: 18)],
          ]),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AuraType.sans(12, a.inkFaint)),
        ]),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime month;
  final Set<String> studied, solved;
  final int activeCount;
  final VoidCallback? onPrev, onNext;
  final ValueChanged<DateTime> onDay;
  const _CalendarCard({
    required this.month,
    required this.studied,
    required this.solved,
    required this.activeCount,
    required this.onPrev,
    required this.onNext,
    required this.onDay,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1; // Monday first

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(children: [
        Row(children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: onPrev,
            icon: const Icon(CupertinoIcons.chevron_left, size: 18),
          ),
          Expanded(
            child: Column(children: [
              Text('${_months[month.month - 1]} ${month.year}',
                  style: AuraType.serif(18, a.ink)),
              Text('$activeCount ${activeCount == 1 ? 'day' : 'days'} studied',
                  style: AuraType.sans(12, a.inkFaint)),
            ]),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: onNext,
            icon: const Icon(CupertinoIcons.chevron_right, size: 18),
          ),
        ]),
        const SizedBox(height: 6),
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.1,
          child: Column(children: [
            Row(children: [
              for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(d,
                        style: AuraType.sans(11.5, a.inkFaint,
                            weight: FontWeight.w600)),
                  ),
                ),
            ]),
            const SizedBox(height: 4),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (int i = 0; i < lead; i++) const SizedBox.shrink(),
                for (int d = 1; d <= days; d++)
                  _DayCell(
                    date: DateTime(month.year, month.month, d),
                    today: today,
                    studied: studied
                        .contains(dayKey(DateTime(month.year, month.month, d))),
                    solved: solved
                        .contains(dayKey(DateTime(month.year, month.month, d))),
                    onTap: onDay,
                  ),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 6),
        Text('Tap a day to open its question.',
            style: AuraType.sans(12, a.inkFaint)),
      ]),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date, today;
  final bool studied, solved;
  final ValueChanged<DateTime> onTap;
  const _DayCell({
    required this.date,
    required this.today,
    required this.studied,
    required this.solved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final future = date.isAfter(today);
    final isToday = isSameDay(date, today);
    final fill = studied ? a.accent : Colors.transparent;
    final text = studied
        ? a.onAccent
        : (future ? a.inkFaint.withValues(alpha: 0.5) : a.ink);
    return Semantics(
      button: !future,
      label: '${date.day} ${_months[date.month - 1]}'
          '${studied ? ', studied' : ''}${solved ? ', question solved' : ''}'
          '${isToday ? ', today' : ''}',
      excludeSemantics: true,
      child: InkResponse(
        onTap: future ? null : () => onTap(date),
        radius: 22,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: isToday && !studied
                    ? Border.all(color: a.accent, width: 1.4)
                    : null,
              ),
              child: Text('${date.day}',
                  style: AuraType.sans(13.5, text,
                      weight: studied || isToday
                          ? FontWeight.w600
                          : FontWeight.w400)),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: solved ? a.accent : Colors.transparent,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MockOfTheDay extends ConsumerWidget {
  final String date;
  const _MockOfTheDay({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mock = ref.watch(dailyMockProvider(date));
    return mock.when(
      loading: () => const GlassListRow(
        icon: CupertinoIcons.stopwatch,
        title: 'Mock of the day',
        subtitle: 'Loading…',
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (paper) => paper == null
          ? const SizedBox.shrink()
          : GlassListRow(
              icon: CupertinoIcons.stopwatch,
              title: 'Mock of the day',
              subtitle:
                  '${paper.title} · ${paper.questionCount} Qs. Finishing it counts as studying today.',
              onTap: () => context.push(paper.examRoute(study: false)),
            ),
    );
  }
}

String formatDuration(int seconds) {
  final m = (seconds / 60).round();
  if (seconds > 0 && m == 0) return '<1 min';
  if (m < 60) return '$m min';
  return '${m ~/ 60} h ${m % 60} min';
}

const _sectionLabels = {
  'pyq': 'PYQ',
  'mock': 'Mock tests',
  'cards': 'Cards',
  'read': 'Reading'
};
const _subLabels = {
  'gk': 'GK',
  'english': 'English',
  'syllabus': 'Syllabus',
  'news': 'News',
  'tutor': 'AI tutor',
  'daily': 'Daily question',
  'general': 'General',
  'streak': 'Streak',
};

String subLabel(String sub) =>
    LearnTopic.values.asNameMap()[sub]?.label ?? _subLabels[sub] ?? sub;

class _TimeCard extends StatelessWidget {
  final Map<String, Map<String, int>> data;
  const _TimeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final order = ['pyq', 'mock', 'cards', 'read'];
    final colors = [a.accent, a.info, a.success, a.inkFaint];
    final totals = [for (final s in order) TimeTracker.sectionTotal(data, s)];
    final total = totals.fold(0, (x, y) => x + y);

    if (total == 0) {
      return GlassCard(
        child: Text(
          'Study time appears here as you use the app. It is counted only while '
          'Dawnlit is open, and stays on this phone.',
          style: AuraType.sans(14, a.inkMuted, height: 1.5),
        ),
      );
    }

    final cards = data['cards'] ?? const {};
    final cardsTotal = TimeTracker.sectionTotal(data, 'cards');
    final topics = cards.entries.toList()
      ..sort((x, y) => y.value.compareTo(x.value));

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(
            width: 128,
            height: 128,
            child: CustomPaint(
              painter: _DonutPainter(
                values: [for (final t in totals) t.toDouble()],
                colors: colors,
                track: a.hairline,
              ),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    width: 76,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(formatDuration(total),
                          textAlign: TextAlign.center,
                          style: AuraType.digits(17, a.ink,
                              weight: FontWeight.w600)),
                    ),
                  ),
                  Text('total', style: AuraType.sans(11, a.inkFaint)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(children: [
              for (int i = 0; i < order.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                          color: colors[i], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_sectionLabels[order[i]]!,
                          style: AuraType.sans(13.5, a.ink)),
                    ),
                    Text(totals[i] == 0 ? '—' : formatDuration(totals[i]),
                        style: AuraType.digits(13, a.inkMuted)),
                  ]),
                ),
            ]),
          ),
        ]),
        if (cardsTotal > 0) ...[
          const SizedBox(height: 18),
          Divider(color: a.hairline),
          const SizedBox(height: 14),
          const Eyebrow('Cards by topic'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 16,
            children: [
              for (final t in topics.take(6))
                _TopicRing(
                    label: subLabel(t.key),
                    seconds: t.value,
                    share: t.value / cardsTotal),
            ],
          ),
        ],
      ]),
    );
  }
}

class _TopicRing extends StatelessWidget {
  final String label;
  final int seconds;
  final double share;
  const _TopicRing(
      {required this.label, required this.seconds, required this.share});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return SizedBox(
      width: 86,
      child: Column(children: [
        SizedBox(
          width: 62,
          height: 62,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: share.clamp(0.02, 1),
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: a.hairline,
                color: a.accent,
              ),
            ),
            Text('${(share * 100).round()}%',
                style: AuraType.digits(12.5, a.ink, weight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              style: AuraType.sans(12.5, a.ink, weight: FontWeight.w500)),
        ),
        Text(formatDuration(seconds), style: AuraType.sans(11.5, a.inkFaint)),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color track;
  _DonutPainter(
      {required this.values, required this.colors, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(arc, 0, math.pi * 2, false, paint..color = track);
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    const gap = 0.05;
    var start = -math.pi / 2;
    final nonZero = values.where((v) => v > 0).length;
    for (int i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = values[i] / total * math.pi * 2;
      final drawn = nonZero > 1 ? math.max(0.0, sweep - gap) : sweep;
      canvas.drawArc(arc, start + (nonZero > 1 ? gap / 2 : 0), drawn, false,
          paint..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values.toString() != values.toString() || old.track != track;
}

class _CoinsCard extends StatelessWidget {
  final CoinState state;
  const _CoinsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final ways = const [
      (
        'PYQ of the day',
        '+${CoinReward.dailyCorrect} right, +${CoinReward.dailyTried} for trying'
      ),
      ('Finish a paper or mock', '+${CoinReward.finishedPaper}'),
      ('Reach your daily card goal', '+${CoinReward.dailyGoal}'),
      ('Find a hidden coin', '+${CoinReward.hiddenCoin}'),
    ];
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final w in ways)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Expanded(child: Text(w.$1, style: AuraType.sans(14, a.ink))),
              Text(w.$2, style: AuraType.sans(13, a.inkMuted)),
            ]),
          ),
        if (state.events.isNotEmpty) ...[
          const SizedBox(height: 12),
          Divider(color: a.hairline),
          const SizedBox(height: 10),
          const Eyebrow('Recent'),
          const SizedBox(height: 8),
          for (final e in state.events.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(
                  child: Text('${e.reason}  ·  ${e.date}',
                      style: AuraType.sans(13, a.inkMuted)),
                ),
                Text('+${e.amount}',
                    style: AuraType.digits(13.5, a.success,
                        weight: FontWeight.w600)),
              ]),
            ),
        ],
        const SizedBox(height: 12),
        Text('Coins are a score for showing up. They have no cash value.',
            style: AuraType.sans(12, a.inkFaint)),
      ]),
    );
  }
}
