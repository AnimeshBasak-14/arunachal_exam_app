import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../data/study_plan_provider.dart';

/// Shows the 2-step setup sheet on first launch, or allows editing from settings.
Future<void> showStudyPlanSheet(
  BuildContext context, {
  bool isFirstRun = false,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StudyPlanSheet(isFirstRun: isFirstRun),
  );
}

class _StudyPlanSheet extends ConsumerStatefulWidget {
  final bool isFirstRun;
  const _StudyPlanSheet({required this.isFirstRun});

  @override
  ConsumerState<_StudyPlanSheet> createState() => _StudyPlanSheetState();
}

class _StudyPlanSheetState extends ConsumerState<_StudyPlanSheet> {
  int _step = 0; // 0: Exam date · 1: Study time & daily goal
  DateTime? _examDate;
  int _reminderHour = 19;
  int _reminderMinute = 0;
  bool _remindersEnabled = false;
  int _dailyGoal = 20;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    final plan = ref.read(studyPlanProvider);
    _examDate = plan.examDate;
    _reminderHour = plan.reminderHour;
    _reminderMinute = plan.reminderMinute;
    _remindersEnabled = plan.remindersEnabled;
    _dailyGoal = plan.dailyGoal;
  }

  String _formatDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatTime(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _examDate != null && _examDate!.isAfter(now)
        ? _examDate!
        : now.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      helpText: 'Select your exam date',
    );
    if (picked != null) {
      setState(() => _examDate = picked);
    }
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      helpText: 'Select daily reminder time',
    );
    if (picked != null) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
    }
  }

  Future<void> _toggleReminders(bool enabled) async {
    if (!enabled) {
      setState(() {
        _remindersEnabled = false;
        _permissionDenied = false;
      });
      return;
    }

    final success = await ref.read(studyPlanProvider.notifier).setReminder(
          enabled: true,
          hour: _reminderHour,
          minute: _reminderMinute,
        );
    if (!mounted) return;
    setState(() {
      _remindersEnabled = success;
      _permissionDenied = !success;
    });
  }

  Future<void> _saveAndClose() async {
    await ref.read(studyPlanProvider.notifier).completeSetup(
      examDate: _examDate,
      remindersEnabled: _remindersEnabled,
      reminderHour: _reminderHour,
      reminderMinute: _reminderMinute,
      dailyGoal: _dailyGoal,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _skip() async {
    await ref.read(studyPlanProvider.notifier).skipSetup();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: a.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: a.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(AuraSpace.gutter, 16, AuraSpace.gutter, 16 + bottomInset),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: _step == 0 ? _buildStep1(a) : _buildStep2(a),
      ),
    );
  }

  Widget _buildStep1(Aura a) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: a.hairline,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Eyebrow('Step 1 of 2 · Exam Timeline'),
            const Spacer(),
            if (widget.isFirstRun)
              TextButton(
                onPressed: _skip,
                child: Text('Skip for now', style: AuraType.sans(13, a.inkMuted)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('When is your exam?', style: AuraType.serif(26, a.ink, height: 1.2)),
        const SizedBox(height: 8),
        Text(
          'Pick your target date so Dawnlit can show days left. You can change this anytime.',
          style: AuraType.sans(14, a.inkMuted, height: 1.45),
        ),
        const SizedBox(height: 24),
        GlassCard(
          onTap: _pickDate,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(CupertinoIcons.calendar, size: 20, color: a.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _examDate == null ? 'Choose your exam date' : _formatDate(_examDate!),
                  style: AuraType.sans(
                    15,
                    _examDate == null ? a.inkMuted : a.ink,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(CupertinoIcons.chevron_forward, size: 16, color: a.inkFaint),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _examDate = null;
                _step = 1;
              });
            },
            child: Text("I don't know yet", style: AuraType.sans(14, a.inkMuted)),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: () => setState(() => _step = 1),
          child: const Text('Next: Choose study time'),
        ),
      ],
    );
  }

  Widget _buildStep2(Aura a) {
    const timePresets = [
      (7, 0, '7:00 AM'),
      (13, 0, '1:00 PM'),
      (18, 0, '6:00 PM'),
      (19, 0, '7:00 PM'),
      (21, 0, '9:00 PM'),
    ];

    const goals = [10, 20, 30];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: a.hairline,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            IconButton(
              icon: Icon(CupertinoIcons.back, size: 18, color: a.ink),
              onPressed: () => setState(() => _step = 0),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            const Eyebrow('Step 2 of 2 · Daily Habit'),
          ],
        ),
        const SizedBox(height: 8),
        Text('When will you study?', style: AuraType.serif(26, a.ink, height: 1.2)),
        const SizedBox(height: 6),
        Text(
          'Choose your daily revision time and card target.',
          style: AuraType.sans(14, a.inkMuted, height: 1.45),
        ),
        const SizedBox(height: 20),

        // Reminder Time Presets
        Text('Daily reminder time', style: AuraType.sans(13.5, a.ink, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in timePresets)
              ChoiceChip(
                label: Text(p.$3),
                selected: _reminderHour == p.$1 && _reminderMinute == p.$2,
                onSelected: (sel) {
                  if (sel) {
                    setState(() {
                      _reminderHour = p.$1;
                      _reminderMinute = p.$2;
                    });
                  }
                },
              ),
            ActionChip(
              avatar: Icon(CupertinoIcons.clock, size: 14, color: a.inkMuted),
              label: Text(
                timePresets.any((p) => p.$1 == _reminderHour && p.$2 == _reminderMinute)
                    ? 'Custom'
                    : _formatTime(_reminderHour, _reminderMinute),
              ),
              onPressed: _pickCustomTime,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Daily Card Goal
        Text('Daily card target', style: AuraType.sans(13.5, a.ink, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final g in goals) ...[
              if (g != goals.first) const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      '$g cards\n~${(g / 5).ceil()} min',
                      textAlign: TextAlign.center,
                      style: AuraType.sans(12.5, _dailyGoal == g ? a.accent : a.ink),
                    ),
                  ),
                  selected: _dailyGoal == g,
                  onSelected: (sel) {
                    if (sel) setState(() => _dailyGoal = g);
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // Notification Permission & Switch
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.bell, size: 20, color: a.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily study reminder', style: AuraType.sans(14, a.ink, weight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          'A calm reminder at ${_formatTime(_reminderHour, _reminderMinute)} so you can keep your daily pace.',
                          style: AuraType.sans(12.5, a.inkMuted, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _remindersEnabled,
                    activeTrackColor: a.accent,
                    onChanged: _toggleReminders,
                  ),
                ],
              ),
              if (_permissionDenied) ...[
                const SizedBox(height: 10),
                Text(
                  'Reminders are off. Notification permission was not granted.',
                  style: AuraType.sans(12.5, a.review),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _saveAndClose,
          child: Text(widget.isFirstRun ? 'Save & start preparing' : 'Save changes'),
        ),
      ],
    );
  }
}
