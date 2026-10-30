import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../learn/data/card_photos.dart';
import '../../learn/data/learn_deck.dart';
import '../../../core/data/exam_goals.dart';
import '../../../core/theme/aura.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../core/widgets/aura/exam_goal_sheet.dart';
import '../../../core/widgets/aura/user_avatar.dart';
import '../../../core/widgets/aura/wordmark.dart';
import '../../auth/view/auth_widgets.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../plan/data/study_plan_provider.dart';
import '../../plan/view/study_plan_sheet.dart';
import '../../streak/view/coin_widgets.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final a = context.aura;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'Your progress is saved to your account. Sign in again any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AuraType.sans(14, a.inkMuted, weight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(minimumSize: const Size(110, 46)),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(studyPlanProvider.notifier).cancelReminders();
      await ref.read(authViewModelProvider.notifier).logout();
      if (context.mounted) context.go('/welcome');
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final vm = ref.read(authViewModelProvider.notifier);
    final password = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final a = ctx.aura;
        return AlertDialog(
          title: const Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  "This permanently deletes your profile, test history and sign-in. It can't be undone."),
              if (vm.hasPassword) ...[
                const SizedBox(height: 16),
                PasswordField(
                    controller: password,
                    label: 'Confirm with your password',
                    action: TextInputAction.done),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                    "You'll be asked to choose your Google account to confirm.",
                    style: AuraType.sans(13.5, a.inkMuted, height: 1.45)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style:
                      AuraType.sans(14, a.inkMuted, weight: FontWeight.w600)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: a.danger,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(110, 46)),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final done =
        await vm.deleteAccount(password: vm.hasPassword ? password.text : null);
    if (!context.mounted) return;
    if (done) {
      await ref.read(studyPlanProvider.notifier).cancelReminders();
      if (!context.mounted) return;
      context.go('/welcome');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account has been deleted.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ref.read(authViewModelProvider).errorMessage ??
              'Could not delete the account.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final user = ref.watch(authViewModelProvider).user;
    final goal = ref.watch(examGoalProvider);
    final plan = ref.watch(studyPlanProvider);
    final mode = ref.watch(themeModeProvider);
    final photosOn = ref.watch(cardPhotosProvider);
    final photoTopicSet = ref.watch(cardPhotoTopicsProvider);
    final name = (user?.name ?? '').trim();
    const modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

    final planSubtitle = plan.examDate != null
        ? '${plan.deadlineLabel() ?? 'Exam date set'} · ${plan.dailyGoal} cards/day'
        : '${plan.dailyGoal} cards/day · ${plan.remindersEnabled ? plan.reminderTimeString : 'Reminders off'}';

    return AuraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () => context.pop(),
            icon: const Icon(CupertinoIcons.back),
          ),
          actions: const [HiddenCoin('account'), SizedBox(width: 6)],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
              AuraSpace.gutter, 24, AuraSpace.gutter, 40),
          children: [
            Row(
              children: [
                UserAvatar(name: name, pic: user?.profilePic),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? 'Aspirant' : name,
                          style: AuraType.serif(24, a.ink)),
                      if ((user?.email ?? '').isNotEmpty)
                        Text(user!.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AuraType.sans(13.5, a.inkMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Eyebrow('Preparation'),
            const SizedBox(height: 10),
            GlassList(children: [
              GlassListRow(
                icon: CupertinoIcons.scope,
                title: 'Exam goal',
                subtitle: goal.name,
                onTap: () => showExamGoalSheet(context),
              ),
              GlassListRow(
                icon: CupertinoIcons.calendar_today,
                title: 'Study plan',
                subtitle: planSubtitle,
                onTap: () => showStudyPlanSheet(context),
              ),
              GlassListRow(
                icon: CupertinoIcons.clock,
                title: 'Test history',
                onTap: () => context.push('/quiz-history'),
              ),
              GlassListRow(
                icon: CupertinoIcons.bookmark,
                title: 'Bookmarked questions',
                onTap: () => context.push('/bookmarks'),
              ),
            ]),
            const SizedBox(height: 26),
            const Eyebrow('Appearance'),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  for (final m in modes)
                    Expanded(
                      child: _ModeOption(
                        label: switch (m) {
                          ThemeMode.light => 'Light',
                          ThemeMode.dark => 'Dark',
                          _ => 'System',
                        },
                        icon: switch (m) {
                          ThemeMode.light => CupertinoIcons.sun_max,
                          ThemeMode.dark => CupertinoIcons.moon,
                          _ => CupertinoIcons.device_phone_portrait,
                        },
                        selected: mode == m,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(m),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Eyebrow('Test features'),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(CupertinoIcons.photo_on_rectangle,
                          size: 20, color: a.accent),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Flexible(
                                child: Text('Pictures on cards',
                                    style: AuraType.sans(15, a.ink,
                                        weight: FontWeight.w500)),
                              ),
                              const SizedBox(width: 8),
                              Tag('Beta', color: a.review),
                            ]),
                            const SizedBox(height: 3),
                            Text(
                                'Cards feel empty? Show a related photo when one fits. Uses more mobile data.',
                                style: AuraType.sans(12.5, a.inkMuted,
                                    height: 1.45)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: photosOn,
                        onChanged: (v) =>
                            ref.read(cardPhotosProvider.notifier).set(v),
                      ),
                    ]),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: !photosOn
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(34, 14, 6, 4),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Eyebrow('Show pictures in'),
                                    const SizedBox(height: 10),
                                    Wrap(spacing: 8, runSpacing: 8, children: [
                                      for (final t in photoTopics)
                                        FilterChip(
                                          label: Text(t.label),
                                          selected: photoTopicSet.contains(t),
                                          onSelected: (_) => ref
                                              .read(cardPhotoTopicsProvider
                                                  .notifier)
                                              .toggle(t),
                                        ),
                                    ]),
                                    const SizedBox(height: 10),
                                    Text(
                                        'Not every card gets one, only cards where a matching photo exists: a battle, a person, an animal, a place. English and vocabulary never show pictures.',
                                        style: AuraType.sans(12, a.inkFaint,
                                            height: 1.45)),
                                  ]),
                            ),
                    ),
                  ]),
            ),
            const SizedBox(height: 26),
            const Eyebrow('Account'),
            const SizedBox(height: 10),
            GlassList(children: [
              GlassListRow(
                icon: CupertinoIcons.person,
                title: 'Edit profile',
                onTap: () => context.push('/edit-profile'),
              ),
              GlassListRow(
                icon: CupertinoIcons.lock,
                title: 'Change password',
                onTap: () => context.push('/change-password'),
              ),
              GlassListRow(
                icon: CupertinoIcons.square_arrow_right,
                title: 'Sign out',
                trailing: const SizedBox.shrink(),
                onTap: () => _signOut(context, ref),
              ),
            ]),
            const SizedBox(height: 26),
            const Eyebrow('About'),
            const SizedBox(height: 10),
            Text(
              '${Wordmark.appName} is an independent study app by ZAP. It is not affiliated with, '
              'endorsed by, or acting for APPSC, APSSB or the Government of Arunachal Pradesh. '
              'Always confirm notifications, dates and syllabus with the official recruiting board.',
              style: AuraType.sans(12.5, a.inkFaint, height: 1.55),
            ),
            const SizedBox(height: 26),
            Center(
              child: TextButton(
                onPressed: () => _deleteAccount(context, ref),
                style: TextButton.styleFrom(foregroundColor: a.danger),
                child: const Text('Delete account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeOption(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? a.accentSoft : Colors.transparent,
            border: Border.all(
                color: selected
                    ? a.accent.withValues(alpha: 0.4)
                    : Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(icon, size: 19, color: selected ? a.accent : a.inkMuted),
              const SizedBox(height: 4),
              Text(label,
                  style: AuraType.sans(12.5, selected ? a.accent : a.inkMuted,
                      weight: selected ? FontWeight.w600 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
