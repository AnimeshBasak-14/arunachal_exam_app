import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/data/exam_goals.dart';
import '../../../core/theme/aura.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../core/widgets/aura/exam_goal_sheet.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final a = context.aura;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your test history stays on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AuraType.sans(14, a.inkMuted, weight: FontWeight.w600)),
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
      await ref.read(authViewModelProvider.notifier).logout();
      if (context.mounted) context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final user = ref.watch(authViewModelProvider).user;
    final goal = ref.watch(examGoalProvider);
    final mode = ref.watch(themeModeProvider);
    final name = (user?.name ?? '').trim();
    const modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(CupertinoIcons.back),
        ),
      ),
      body: AuraBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AuraSpace.gutter, 0, AuraSpace.gutter, 40),
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: a.accentSoft,
                    border: Border.all(color: a.hairline),
                  ),
                  child: Text(name.isEmpty ? '·' : name[0].toUpperCase(),
                      style: AuraType.serif(24, a.accent, weight: FontWeight.w600)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? 'Aspirant' : name, style: AuraType.serif(24, a.ink)),
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
                        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(m),
                      ),
                    ),
                ],
              ),
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
  const _ModeOption({required this.label, required this.icon, required this.selected, required this.onTap});

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
            border: Border.all(color: selected ? a.accent.withValues(alpha: 0.4) : Colors.transparent),
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
