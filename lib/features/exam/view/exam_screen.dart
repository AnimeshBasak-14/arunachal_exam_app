import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/exam_repository.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/question_repository.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/rank_utils.dart';
import '../../../core/widgets/ai_explain_sheet.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../data/attempt.dart';
import 'question_view.dart';

/// Full-screen exam engine: one question per page, persistent timer, and a
/// question palette drawer. Study mode drops the timer and reveals the key
/// after each answer.
class ExamScreen extends ConsumerStatefulWidget {
  final String examCode;
  final String testType; // 'full', or a question count such as '10'
  final String? testId;
  final String? title;
  final String? subject;
  final String? difficulty;
  final String? paperType; // 'PYQ', 'MOCK' or 'BOTH'
  final int? year;
  final int? durationMinutes;
  final bool isStudyMode;
  final List<Question>? initialQuestions;

  const ExamScreen({
    super.key,
    required this.examCode,
    required this.testType,
    this.testId,
    this.title,
    this.subject,
    this.difficulty,
    this.paperType,
    this.year,
    this.durationMinutes,
    this.isStudyMode = false,
    this.initialQuestions,
  });

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _page = PageController();
  final _remaining = ValueNotifier<int>(0);

  List<Question> _qs = const [];
  bool _loading = true;
  final Map<String, String> _answers = {};
  final Set<String> _marked = {};
  final Set<String> _visited = {};
  int _index = 0;
  int _totalSeconds = 0;
  Timer? _timer;
  bool _submitted = false;

  bool get _study => widget.isStudyMode;
  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _title {
    if (widget.title?.trim().isNotEmpty ?? false) return widget.title!.trim();
    if (_qs.isNotEmpty && _qs.first.testTitle.isNotEmpty) {
      return _qs.first.testTitle;
    }
    if (widget.subject?.isNotEmpty ?? false) {
      return '${widget.subject} practice';
    }
    return '${widget.examCode} mock test';
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuestions;
    if (initial != null && initial.isNotEmpty) {
      _ready(List.of(initial),
          widget.durationMinutes ?? _bucketMinutes(initial.length));
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    _remaining.dispose();
    super.dispose();
  }

  static int _bucketMinutes(int n) => n <= 10 ? 15 : (n <= 20 ? 30 : 60);

  void _ready(List<Question> qs, int minutes, {int? seconds}) {
    _totalSeconds = seconds ?? minutes * 60;
    _remaining.value = _totalSeconds;
    setState(() {
      _qs = qs;
      _loading = false;
      if (qs.isNotEmpty) _visited.add(qs.first.id);
    });
    if (!_study && qs.isNotEmpty) _startTimer();
  }

  /// Same selection rules as before the redesign: a specific paper by
  /// test id, otherwise a pool filtered by exam, type, subject and difficulty.
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final testId = widget.testId;
      if (testId != null && testId.isNotEmpty) {
        final qs = await ExamRepository.instance.fetchQuestionsForTest(testId);
        if (qs.isNotEmpty && mounted) {
          _ready(qs, widget.durationMinutes ?? _bucketMinutes(qs.length));
          return;
        }
      }

      final type = widget.paperType?.toUpperCase() ?? 'MOCK';
      final examQs = await QuestionRepository.fetchLiveQuestions(
          examCode: widget.examCode, paperType: type, year: widget.year);
      var pool =
          examQs.where((q) => q.paperType.toUpperCase() == type).toList();

      if (type == 'MOCK' && pool.isEmpty) {
        final general = await QuestionRepository.fetchLiveQuestions(
            examCode: 'APSSB-MOCK', paperType: 'MOCK');
        pool =
            general.where((q) => q.paperType.toUpperCase() == 'MOCK').toList();
      }
      if (widget.examCode.toUpperCase() == 'ALL') {
        final broad = await QuestionRepository.fetchLiveQuestions(
            examCode: '', paperType: type);
        pool = broad.where((q) => q.paperType.toUpperCase() == type).toList();
      }
      if (pool.isEmpty) {
        pool = await QuestionRepository.fetchLiveQuestions(
            examCode: widget.examCode);
      }

      final subject = widget.subject;
      if (subject != null && subject.isNotEmpty && subject != 'All') {
        final s = subject.toLowerCase();
        final english = s.contains('english') || s.contains('comprehension');
        final filtered = pool.where((q) {
          final qs = q.subject.toLowerCase();
          if (english) {
            return qs.contains('english') ||
                qs.contains('comprehension') ||
                qs.contains('grammar') ||
                qs.contains('reading');
          }
          return qs.contains(s) || s.contains(qs);
        }).toList();
        if (filtered.isNotEmpty) pool = filtered;
      }

      final diff = widget.difficulty;
      if (diff != null && diff.isNotEmpty && diff != 'All Levels') {
        final filtered = pool
            .where((q) => q.difficulty.toLowerCase() == diff.toLowerCase())
            .toList();
        if (filtered.isNotEmpty) pool = filtered;
      }

      if (!mounted) return;
      if (pool.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final full = widget.testType.toLowerCase() == 'full';
      final count = int.tryParse(widget.testType) ??
          (full
              ? pool.length
              : RemoteConfigService.instance.dailyTestQuestionCount);
      final picked = full
          ? List<Question>.from(pool)
          : (List<Question>.from(pool)..shuffle(math.Random()))
              .take(count)
              .toList();

      final int seconds;
      if ((widget.durationMinutes ?? 0) > 0) {
        seconds = widget.durationMinutes! * 60;
      } else if (full && picked.first.timeLimitMins > 0) {
        seconds = picked.first.timeLimitMins * 60;
      } else {
        seconds = math.max(300, picked.length * 60);
      }
      _ready(picked, 0, seconds: seconds);
    } catch (e) {
      debugPrint('[Exam] load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining.value <= 0) {
        t.cancel();
        if (_isMobile) HapticFeedback.heavyImpact();
        _submit();
        return;
      }
      _remaining.value--;
      if (_isMobile && _remaining.value <= 5 && _remaining.value > 0) {
        HapticFeedback.lightImpact();
      }
    });
  }

  void _goTo(int i) {
    if (i < 0 || i >= _qs.length) return;
    _page.animateToPage(i,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic);
  }

  void _select(Question q, String letter) {
    if (_study && _answers.containsKey(q.id)) return; // first answer is final
    setState(() => _answers[q.id] = letter);
  }

  ({int answered, int marked, int notAnswered}) get _counts {
    final answered = _qs.where((q) => _answers.containsKey(q.id)).length;
    return (
      answered: answered,
      marked: _qs.where((q) => _marked.contains(q.id)).length,
      notAnswered: _qs.length - answered,
    );
  }

  Future<void> _confirmSubmit() async {
    final c = _counts;
    final a = context.aura;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_study ? 'Finish session?' : 'Submit test?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryLine('Answered', c.answered, a.accent),
            _SummaryLine('Marked for review', c.marked, a.review),
            _SummaryLine('Not answered', c.notAnswered, a.inkFaint),
            if (!_study) ...[
              const SizedBox(height: 14),
              Text('You cannot change answers after submitting.',
                  style: AuraType.sans(13.5, a.inkMuted)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep going',
                style: AuraType.sans(14, a.inkMuted, weight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(minimumSize: const Size(110, 46)),
            child: Text(_study ? 'Finish' : 'Submit'),
          ),
        ],
      ),
    );
    if (ok == true) _submit();
  }

  Future<bool> _confirmLeave() async {
    final a = context.aura;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this test?'),
        content: Text(_study
            ? 'Your progress in this session will not be saved.'
            : 'Your answers will be lost and this attempt will not be scored. To get your score, submit instead.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Leave',
                style: AuraType.sans(14, a.danger, weight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: FilledButton.styleFrom(minimumSize: const Size(110, 46)),
            child: const Text('Stay'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  void _submit() {
    if (_submitted || _qs.isEmpty) return;
    _submitted = true;
    _timer?.cancel();

    int correct = 0, wrong = 0, left = 0, ungraded = 0;
    double score = 0, maxScore = 0;
    for (final q in _qs) {
      if (!q.hasAnswerKey) {
        ungraded++; // no verified key: neither reward nor penalise
        continue;
      }
      maxScore += q.marksPerCorrect;
      final ans = _answers[q.id];
      if (ans == null) {
        left++;
      } else if (ans == q.correctAnswer) {
        correct++;
        score += q.marksPerCorrect;
      } else {
        wrong++;
        score -= q.negativeMarks;
      }
    }

    final timeTaken = _study ? 0 : _totalSeconds - _remaining.value;
    final gradable = maxScore > 0;
    final user = ref.read(authViewModelProvider).user;
    final currentRating = user?.rating ?? 1200;

    // Rating: ELO against a 1200 test, plus a speed bonus at >= 40% accuracy.
    int ratingChange = 0, speedBonus = 0, totalChange = 0;
    if (gradable && !_study) {
      final actual = (math.max(0, score) / maxScore).toDouble();
      final expected = 1 / (1 + math.pow(10, (1200 - currentRating) / 400));
      ratingChange = (32 * (actual - expected)).round();
      if (actual >= 0.40 && timeTaken < _totalSeconds && _totalSeconds > 0) {
        speedBonus = (_remaining.value / _totalSeconds * 10).round();
      }
      totalChange = ((ratingChange + speedBonus) *
              RemoteConfigService.instance.trophiesMultiplier)
          .round();
      if (user != null) {
        ref.read(authViewModelProvider.notifier).updateRating(totalChange);
      }
    }

    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final date =
        '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}';

    final record = <String, dynamic>{
      'examCode': widget.examCode,
      'testTitle': _title,
      'testId': widget.testId,
      'mode': _study ? 'study' : 'exam',
      'score': score,
      'maxScore': maxScore,
      'ratingChange': ratingChange,
      'speedBonus': speedBonus,
      'newRating': math.max(0, currentRating + totalChange),
      'correct': correct,
      'wrong': wrong,
      'left': left,
      'ungraded': ungraded,
      'timeTaken': timeTaken,
      'date': date,
      'completedAt': date,
      'selectedAnswers': Map<String, String>.from(_answers),
      'questions': _qs.map(Attempt.questionToMap).toList(),
    };
    _persist(record, currentRating);
    context.pushReplacement('/mock-test-result', extra: record);
  }

  Future<void> _persist(Map<String, dynamic> record, int currentRating) async {
    // Read providers before the first await: this screen is replaced by the
    // result screen and disposed while saving continues.
    final storage = ref.read(storageServiceProvider);
    final user = ref.read(authViewModelProvider).user;
    final firebase = ref.read(firebaseServiceProvider);
    // A finished paper counts as studying today.
    StreakService(ref.read(sharedPreferencesProvider)).checkAndUpdateStreak();

    final history = List<String>.from(storage.getQuizHistory())
      ..insert(0, jsonEncode(record));
    await storage.saveQuizHistory(history);

    try {
      await firebase.logQuizCompleted(
        examCode: widget.examCode,
        score: record['score'] as double,
        maxScore: record['maxScore'] as double,
        trophiesChange:
            (record['ratingChange'] as int) + (record['speedBonus'] as int),
        timeTakenSeconds: record['timeTaken'] as int,
        rankTier: RankUtils.getTierName(currentRating),
      );
      if (user != null && user.email.isNotEmpty) {
        await firebase.saveQuizResultToFirestore(user.email, {
          'examCode': widget.examCode,
          'testTitle': record['testTitle'],
          'mode': record['mode'],
          'score': record['score'],
          'maxScore': record['maxScore'],
          'ratingChange': record['ratingChange'],
          'speedBonus': record['speedBonus'],
          'correct': record['correct'],
          'wrong': record['wrong'],
          'left': record['left'],
          'timeTakenSeconds': record['timeTaken'],
          'date': record['date'],
        });
      }
    } catch (_) {}
  }

  /// "Q 11–15" for questions that share a passage.
  String? _passageRange(int i) {
    final q = _qs[i];
    final text = q.passageOrDirection?.trim() ?? '';
    if (text.isEmpty) return null;
    String key(Question x) =>
        x.passageId ?? x.groupId ?? x.passageOrDirection?.trim() ?? '';
    final k = key(q);
    var s = i, e = i;
    while (s > 0 && key(_qs[s - 1]) == k) {
      s--;
    }
    while (e < _qs.length - 1 && key(_qs[e + 1]) == k) {
      e++;
    }
    return s == e ? 'Q ${s + 1}' : 'Q ${s + 1}–${e + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (_scaffold.currentState?.isEndDrawerOpen ?? false) {
          navigator.pop();
          return;
        }
        if (_loading || _qs.isEmpty || _submitted || await _confirmLeave()) {
          navigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffold,
        backgroundColor: a.bg,
        endDrawer: _qs.isEmpty
            ? null
            : _PaletteDrawer(
                questions: _qs,
                index: _index,
                answers: _answers,
                marked: _marked,
                visited: _visited,
                study: _study,
                onJump: (i) {
                  Navigator.of(context).pop();
                  _page.jumpToPage(i);
                },
                onSubmit: () {
                  Navigator.of(context).pop();
                  _confirmSubmit();
                },
              ),
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                title: _title,
                study: _study,
                remaining: _remaining,
                answered: _counts.answered,
                total: _qs.length,
                onClose: () => Navigator.maybePop(context),
                onPalette: _qs.isEmpty
                    ? null
                    : () => _scaffold.currentState?.openEndDrawer(),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(end: _qs.isEmpty ? 0 : (_index + 1) / _qs.length),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 1.5,
                  backgroundColor: a.hairline,
                ),
              ),
              Expanded(child: _body(a)),
              if (_qs.isNotEmpty) _bottomBar(a),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(Aura a) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 1.6)),
            const SizedBox(height: 18),
            Text('Preparing your paper…', style: AuraType.sans(14, a.inkMuted)),
          ],
        ),
      );
    }
    if (_qs.isEmpty) {
      return Center(
        child: AuraEmpty(
          icon: CupertinoIcons.wifi_slash,
          title: 'No questions found',
          message: 'Check your internet connection and try again.',
          actionLabel: 'Retry',
          onAction: _load,
        ),
      );
    }
    final bookmarks = ref.watch(bookmarkedQuestionsProvider);
    return PageView.builder(
      controller: _page,
      itemCount: _qs.length,
      onPageChanged: (i) => setState(() {
        _index = i;
        _visited.add(_qs[i].id);
      }),
      itemBuilder: (_, i) {
        final q = _qs[i];
        return QuestionView(
          key: ValueKey(q.id),
          question: q,
          number: i + 1,
          total: _qs.length,
          selected: _answers[q.id],
          reveal: _study && _answers.containsKey(q.id),
          bookmarked: bookmarks.contains(q.id),
          passageRange: _passageRange(i),
          onSelect: (letter) => _select(q, letter),
          onBookmark: () => ref
              .read(bookmarkedQuestionsProvider.notifier)
              .toggleBookmark(q.id),
          onExplain: () => showAiExplainSheet(
            context,
            highlightedText: '${q.questionText}\n\n${q.options.join('\n')}',
          ),
        );
      },
    );
  }

  Widget _bottomBar(Aura a) {
    final q = _qs[_index];
    final isLast = _index == _qs.length - 1;
    final marked = _marked.contains(q.id);
    final answered = _answers.containsKey(q.id);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
      decoration: BoxDecoration(
        color: a.bg,
        border: Border(top: BorderSide(color: a.hairline, width: 0.8)),
      ),
      child: LayoutBuilder(builder: (context, c) {
        // Narrow phones or large text: icon-only secondary actions.
        final compact =
            c.maxWidth < 300 + 60 * MediaQuery.textScalerOf(context).scale(1);
        void toggleMark() =>
            setState(() => marked ? _marked.remove(q.id) : _marked.add(q.id));
        final flag = Icon(
            marked ? CupertinoIcons.flag_fill : CupertinoIcons.flag,
            size: 18);
        return Row(
          children: [
            if (!_study)
              compact
                  ? IconButton(
                      tooltip: marked ? 'Unmark review' : 'Mark for review',
                      onPressed: toggleMark,
                      color: marked ? a.review : a.inkMuted,
                      icon: flag,
                    )
                  : TextButton.icon(
                      onPressed: toggleMark,
                      style: TextButton.styleFrom(
                          foregroundColor: marked ? a.review : a.inkMuted),
                      icon: flag,
                      label: Text(marked ? 'Marked' : 'Review'),
                    ),
            if (!_study && answered)
              compact
                  ? IconButton(
                      tooltip: 'Clear answer',
                      onPressed: () => setState(() => _answers.remove(q.id)),
                      color: a.inkMuted,
                      icon: const Icon(CupertinoIcons.arrow_counterclockwise,
                          size: 18),
                    )
                  : TextButton(
                      onPressed: () => setState(() => _answers.remove(q.id)),
                      style: TextButton.styleFrom(foregroundColor: a.inkMuted),
                      child: const Text('Clear'),
                    ),
            const Spacer(),
            IconButton.outlined(
              tooltip: 'Previous question',
              onPressed: _index == 0 ? null : () => _goTo(_index - 1),
              style: IconButton.styleFrom(
                side: BorderSide(color: a.hairline),
                fixedSize: const Size(48, 48),
              ),
              icon: const Icon(CupertinoIcons.chevron_left, size: 18),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: isLast ? _confirmSubmit : () => _goTo(_index + 1),
              style: FilledButton.styleFrom(
                minimumSize: const Size(108, 48),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(isLast ? (_study ? 'Finish' : 'Submit') : 'Next'),
            ),
          ],
        );
      }),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final bool study;
  final ValueNotifier<int> remaining;
  final int answered;
  final int total;
  final VoidCallback onClose;
  final VoidCallback? onPalette;

  const _TopBar({
    required this.title,
    required this.study,
    required this.remaining,
    required this.answered,
    required this.total,
    required this.onClose,
    required this.onPalette,
  });

  static String _clock(int s) {
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Leave test',
            onPressed: onClose,
            icon: Icon(CupertinoIcons.xmark, size: 20, color: a.ink),
          ),
          Expanded(
            child: Column(
              children: [
                if (study)
                  Text('Study mode',
                      style:
                          AuraType.sans(16, a.accent, weight: FontWeight.w600))
                else
                  ValueListenableBuilder<int>(
                    valueListenable: remaining,
                    builder: (_, s, __) => AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: AuraType.digits(20, s <= 300 ? a.danger : a.ink,
                          weight: FontWeight.w500),
                      child: Text(_clock(s),
                          semanticsLabel: 'Time left ${_clock(s)}'),
                    ),
                  ),
                const SizedBox(height: 1),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AuraType.sans(11.5, a.inkFaint)),
              ],
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: onPalette,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: a.hairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.square_grid_2x2,
                        size: 16, color: a.ink),
                    const SizedBox(width: 7),
                    Text('$answered/$total', style: AuraType.digits(13, a.ink)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteDrawer extends StatelessWidget {
  final List<Question> questions;
  final int index;
  final Map<String, String> answers;
  final Set<String> marked;
  final Set<String> visited;
  final bool study;
  final ValueChanged<int> onJump;
  final VoidCallback onSubmit;

  const _PaletteDrawer({
    required this.questions,
    required this.index,
    required this.answers,
    required this.marked,
    required this.visited,
    required this.study,
    required this.onJump,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final width = math.min(360.0, MediaQuery.sizeOf(context).width * 0.88);
    final answered = questions.where((q) => answers.containsKey(q.id)).length;
    return Drawer(
      width: width,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Question palette', style: AuraType.serif(23, a.ink)),
              const SizedBox(height: 4),
              Text('$answered of ${questions.length} answered',
                  style: AuraType.sans(13, a.inkMuted)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _Legend(fill: a.accent, label: 'Answered'),
                  if (!study) _Legend(fill: a.review, label: 'Marked'),
                  _Legend(border: a.danger, label: 'Not answered'),
                  _Legend(border: a.hairline, label: 'Not visited'),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: a.hairline),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 54,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: questions.length,
                  itemBuilder: (_, i) {
                    final id = questions[i].id;
                    return _Cell(
                      number: i + 1,
                      current: i == index,
                      answered: answers.containsKey(id),
                      marked: marked.contains(id),
                      visited: visited.contains(id),
                      onTap: () => onJump(i),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: Text(study ? 'Finish session' : 'Submit test'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final int number;
  final bool current, answered, marked, visited;
  final VoidCallback onTap;

  const _Cell({
    required this.number,
    required this.current,
    required this.answered,
    required this.marked,
    required this.visited,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    Color fill = Colors.transparent;
    Color border = a.hairline;
    Color text = a.inkFaint;
    if (marked) {
      fill = a.review;
      border = a.review;
      text = a.onAccent;
    } else if (answered) {
      fill = a.accent;
      border = a.accent;
      text = a.onAccent;
    } else if (visited) {
      border = a.danger.withValues(alpha: 0.7);
      text = a.danger;
    }
    return Semantics(
      button: true,
      label: 'Question $number',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(
                color: current ? a.ink : border, width: current ? 2 : 1),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.15,
                child: Text('$number',
                    style: AuraType.digits(13, text, weight: FontWeight.w600)),
              ),
              if (marked && answered)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: a.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: a.surfaceSolid, width: 1.5),
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

class _Legend extends StatelessWidget {
  final Color? fill;
  final Color? border;
  final String label;
  const _Legend({this.fill, this.border, required this.label});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill ?? Colors.transparent,
            border: Border.all(color: fill ?? border ?? a.hairline, width: 1.2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AuraType.sans(12, a.inkMuted)),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SummaryLine(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AuraType.sans(14.5, a.ink))),
          Text('$value', style: AuraType.digits(15, a.ink)),
        ],
      ),
    );
  }
}
