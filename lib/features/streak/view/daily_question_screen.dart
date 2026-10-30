import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/question_repository.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../learn/view/study_widgets.dart';
import '../data/coins.dart';
import '../data/daily.dart';
import '../data/day_key.dart';
import '../data/time_tracker.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _short = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

/// The PYQ of the day for [date] (`yyyy-MM-dd`). Today's question earns
/// streak and coins; earlier days are practice only.
class DailyQuestionScreen extends ConsumerWidget {
  final String date;
  const DailyQuestionScreen({super.key, required this.date});

  /// Strips a leading "(a) " so the letter badge isn't doubled.
  static String cleanOption(String o) =>
      o.replaceFirst(RegExp(r'^\s*\(?[a-dA-D][\).]\s*'), '').trim();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = parseDayKey(date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (day == null || day.isAfter(today)) {
      return StudyPage(
        title: 'PYQ of the day',
        children: [
          AuraEmpty(
            icon: CupertinoIcons.lock,
            title: day == null ? 'No such day' : 'Not open yet',
            message: day == null
                ? 'That date doesn\'t look right.'
                : 'This question opens on ${day.day} ${_short[day.month - 1]}. Come back then.',
            actionLabel: 'Back to streak',
            onAction: () => context.pop(),
          ),
        ],
      );
    }

    final isToday = isSameDay(day, today);
    final async = ref.watch(dailyQuestionProvider(date));
    final result = ref.watch(dailyLogProvider)[date];

    return TimeTracked(
      section: 'pyq',
      sub: 'daily',
      child: StudyPage(
        title:
            isToday ? 'PYQ of the day' : '${day.day} ${_short[day.month - 1]}',
        coinSpot: null,
        children: [
          Eyebrow(
              '${_weekdays[day.weekday - 1]}, ${day.day} ${_short[day.month - 1]} ${day.year}'),
          const SizedBox(height: 14),
          ...async.when(
            loading: () => const [
              SkeletonBox(height: 28, width: 220),
              SizedBox(height: 14),
              SkeletonBox(height: 90),
              SizedBox(height: 18),
              SkeletonBox(height: 54),
              SizedBox(height: 10),
              SkeletonBox(height: 54),
            ],
            error: (_, __) => [_unavailable(ref)],
            data: (q) => q == null
                ? [_unavailable(ref)]
                : [_body(context, ref, q, result, isToday)],
          ),
        ],
      ),
    );
  }

  Widget _unavailable(WidgetRef ref) => AuraEmpty(
        icon: CupertinoIcons.wifi_slash,
        title: 'Question not available',
        message:
            'We couldn\'t load this day\'s question. Check your connection and try again.',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(dailyQuestionProvider(date)),
      );

  Widget _body(BuildContext context, WidgetRef ref, Question q,
      DailyResult? result, bool isToday) {
    final a = context.aura;
    final answerIdx = 'abcd'.indexOf(q.correctAnswer);
    final coins = isToday ? ref.watch(coinsProvider) : null;
    final earned = coins?.events
            .where((e) => e.reason == 'PYQ of the day' && e.date == date)
            .fold<int>(0, (s, e) => s + e.amount) ??
        0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MetaLine([q.examCode, q.year > 0 ? '${q.year}' : null, q.subject]),
      const SizedBox(height: 10),
      Text(q.questionText, style: AuraType.serif(21, a.ink, height: 1.35)),
      const SizedBox(height: 22),
      for (int i = 0; i < q.options.length && i < 4; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _Option(
            letter: 'ABCD'[i],
            text: cleanOption(q.options[i]),
            state: result == null
                ? _S.idle
                : i == answerIdx
                    ? _S.right
                    : 'abcd'.indexOf(result.picked) == i
                        ? _S.wrong
                        : _S.dim,
            onTap: result != null
                ? null
                : () {
                    final right = i == answerIdx;
                    right
                        ? HapticFeedback.mediumImpact()
                        : HapticFeedback.heavyImpact();
                    ref
                        .read(dailyLogProvider.notifier)
                        .answer(date, 'abcd'[i], right);
                  },
          ),
        ),
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: result == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.correct
                            ? 'Correct'
                            : 'Not quite. The answer is highlighted.',
                        style: AuraType.sans(
                            14.5, result.correct ? a.success : a.danger,
                            weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isToday
                            ? (earned > 0
                                ? '+$earned coins · counted toward your streak'
                                : 'Counted toward your streak')
                            : 'Practice only. Streak and coins count on the day itself.',
                        style: AuraType.sans(13, a.inkMuted),
                      ),
                      if (q.solution.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Eyebrow('Explanation'),
                        const SizedBox(height: 8),
                        Text(q.solution,
                            style:
                                AuraType.sans(14.5, a.inkMuted, height: 1.6)),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: () => context.pop(),
                        child: const Text('Back to streak'),
                      ),
                    ]),
              ),
      ),
    ]);
  }
}

enum _S { idle, right, wrong, dim }

class _Option extends StatelessWidget {
  final String letter, text;
  final _S state;
  final VoidCallback? onTap;
  const _Option(
      {required this.letter,
      required this.text,
      required this.state,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final (border, fill, icon) = switch (state) {
      _S.idle => (a.hairline, a.surface, null),
      _S.right => (
          a.success,
          a.success.withValues(alpha: 0.10),
          CupertinoIcons.checkmark_circle_fill
        ),
      _S.wrong => (
          a.danger,
          a.danger.withValues(alpha: 0.08),
          CupertinoIcons.xmark_circle_fill
        ),
      _S.dim => (a.hairline, Colors.transparent, null),
    };
    final ink = state == _S.dim ? a.inkFaint : a.ink;
    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AuraSpace.radiusS),
        side: BorderSide(
            color: border,
            width: state == _S.idle || state == _S.dim ? 0.8 : 1.6),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AuraSpace.radiusS),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 24,
              child: Text(letter,
                  style:
                      AuraType.sans(14, a.inkFaint, weight: FontWeight.w600)),
            ),
            Expanded(
                child: Text(text, style: AuraType.sans(15, ink, height: 1.4))),
            if (icon != null) ...[
              const SizedBox(width: 10),
              Icon(icon, size: 20, color: border),
            ],
          ]),
        ),
      ),
    );
  }
}
