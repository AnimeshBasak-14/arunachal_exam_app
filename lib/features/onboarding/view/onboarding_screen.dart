import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../core/widgets/aura/exam_goal_sheet.dart';
import '../../../core/widgets/aura/wordmark.dart';
import '../viewmodel/onboarding_viewmodel.dart';

/// First launch: choose the exam you are preparing for.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  void _finish(BuildContext context, WidgetRef ref) {
    ref.read(onboardingViewModelProvider.notifier).completeOnboarding();
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              Row(
                children: [
                  const Wordmark(size: 20),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _finish(context, ref),
                    style: TextButton.styleFrom(foregroundColor: a.inkMuted),
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text('What are you\npreparing for?',
                  style: AuraType.serif(34, a.ink, height: 1.15)),
              const SizedBox(height: 12),
              Text(
                'We will show that exam\'s papers first. You can change this any time.',
                style: AuraType.sans(15, a.inkMuted, height: 1.5),
              ),
              const SizedBox(height: 30),
              ExamGoalList(onSelected: (_) => _finish(context, ref)),
            ],
          ),
        ),
      ),
    );
  }
}
