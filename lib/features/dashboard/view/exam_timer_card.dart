import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../plan/data/countdown.dart';
import '../../plan/data/study_plan_provider.dart';
import '../../plan/view/study_plan_sheet.dart';
import '../../streak/data/questions_today.dart';

/// Exam countdown plus today's question-target ring. The countdown runs to
/// the exam date the student set in their study plan; with no date it asks
/// for one instead of guessing.
class ExamTimerCard extends ConsumerStatefulWidget {
  const ExamTimerCard({super.key});

  @override
  ConsumerState<ExamTimerCard> createState() => _ExamTimerCardState();
}

class _ExamTimerCardState extends ConsumerState<ExamTimerCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Seconds only show inside the last 3 days; otherwise a refresh every 30 s
    // is plenty.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final date = ref.read(studyPlanProvider).examDate;
      if (!mounted || date == null) return;
      final now = DateTime.now();
      if (examCountdown(now, date).ticksEverySecond || now.second % 30 == 0) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final plan = ref.watch(studyPlanProvider);
    final target = ref.watch(dailyQuestionTargetProvider);
    final answered = ref.watch(questionsTodayProvider);
    final done = answered >= target;
    final countdown = plan.examDate == null
        ? null
        : examCountdown(DateTime.now(), plan.examDate!);

    Widget left;
    if (countdown == null) {
      left = _message(a, 'Add your exam date',
          'Watch the months, days and hours count down here.', 'Set exam date');
    } else if (countdown.state == CountdownState.passed) {
      left = _message(a, 'Your exam date has passed',
          'Set the next one to start a new countdown.', 'Set next date');
    } else if (countdown.state == CountdownState.examDay) {
      left = _message(a, 'Today is exam day',
          'Read each question twice. You are ready.', null);
    } else {
      left = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Time to your exam'),
          const SizedBox(height: 10),
          Semantics(
            label: countdown.segments
                .map((s) => '${s.value} ${s.label.toLowerCase()}')
                .join(', '),
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < countdown.segments.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 2, 5, 0),
                        child: Text(':',
                            style: AuraType.digits(28, a.inkFaint,
                                weight: FontWeight.w300)),
                      ),
                    _Segment(countdown.segments[i]),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return GlassCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 14),
      onTap: () => showStudyPlanSheet(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: left),
              const SizedBox(width: 14),
              SizedBox(
                width: 74,
                height: 74,
                child: Semantics(
                  label: '$answered of $target questions answered today',
                  excludeSemantics: true,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: (answered / target).clamp(0, 1).toDouble(),
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        backgroundColor: a.hairline,
                        color: done ? a.success : a.accent,
                      ),
                    ),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('$answered',
                          style: AuraType.digits(20, a.ink,
                              weight: FontWeight.w600)),
                      Text('of $target',
                          style: AuraType.sans(10.5, a.inkFaint)),
                    ]),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: a.hairline, height: 1),
          Row(
            children: [
              Expanded(
                child: Text(
                  done
                      ? 'Question target reached today'
                      : '${target - answered} more ${target - answered == 1 ? 'question' : 'questions'} to reach today\'s target',
                  style: AuraType.sans(12.5, done ? a.success : a.inkMuted,
                      weight: done ? FontWeight.w600 : FontWeight.w400),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/learn'),
                child: Text(done ? 'Keep going' : 'Practise'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _message(Aura a, String title, String body, String? cta) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Exam countdown'),
          const SizedBox(height: 8),
          Text(title, style: AuraType.serif(21, a.ink, height: 1.2)),
          const SizedBox(height: 6),
          Text(body, style: AuraType.sans(13, a.inkMuted, height: 1.4)),
          if (cta != null) ...[
            const SizedBox(height: 10),
            Text(cta,
                style: AuraType.sans(13.5, a.accent, weight: FontWeight.w600)),
          ],
        ],
      );
}

class _Segment extends StatelessWidget {
  final CountdownSegment segment;
  const _Segment(this.segment);

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Column(
      children: [
        Text(segment.value,
            style: AuraType.digits(32, a.ink, weight: FontWeight.w300)),
        Text(segment.label,
            style: AuraType.sans(10, a.inkFaint,
                weight: FontWeight.w600, letterSpacing: 0.8)),
      ],
    );
  }
}
