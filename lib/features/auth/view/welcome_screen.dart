import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../core/widgets/aura/wordmark.dart';
import 'google_sign_in.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 28),
                      const Align(alignment: Alignment.centerLeft, child: Wordmark()),
                      const Spacer(),
                      const SizedBox(height: 48),
                      Text('Prepare with calm.\nPerform with clarity.',
                          style: AuraType.serif(36, a.ink, height: 1.15)),
                      const SizedBox(height: 16),
                      Text(
                        'Previous year papers and exam-condition mock tests for APPSC and APSSB recruitment exams.',
                        style: AuraType.sans(15.5, a.inkMuted, height: 1.55),
                      ),
                      const SizedBox(height: 40),
                      FilledButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('Create account'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('Sign in'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => signInWithGoogle(context, ref),
                        style: TextButton.styleFrom(
                          foregroundColor: a.ink,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('G', style: AuraType.sans(17, a.ink, weight: FontWeight.w700)),
                            const SizedBox(width: 10),
                            const Text('Continue with Google'),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        style: TextButton.styleFrom(foregroundColor: a.inkMuted),
                        child: const Text('Forgot password?'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
