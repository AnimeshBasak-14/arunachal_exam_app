import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../viewmodel/auth_viewmodel.dart';

/// Google sign-in shared by the welcome, login and register screens. New
/// Google accounts get a profile automatically.
Future<void> signInWithGoogle(BuildContext context, WidgetRef ref) async {
  final ok = await ref.read(authViewModelProvider.notifier).signInWithGoogle();
  if (!context.mounted) return;
  if (ok) {
    context.go('/home');
    return;
  }
  final err = ref.read(authViewModelProvider).errorMessage;
  if (err != null && err.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
}

/// "Continue with Google" button used on every auth screen.
class GoogleButton extends ConsumerWidget {
  final bool outlined;
  const GoogleButton({super.key, this.outlined = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final busy = ref.watch(authViewModelProvider).isLoading;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('G', style: AuraType.sans(17, a.ink, weight: FontWeight.w700)),
        const SizedBox(width: 10),
        const Text('Continue with Google'),
      ],
    );
    return outlined
        ? OutlinedButton(onPressed: busy ? null : () => signInWithGoogle(context, ref), child: child)
        : TextButton(
            onPressed: busy ? null : () => signInWithGoogle(context, ref),
            style: TextButton.styleFrom(foregroundColor: a.ink, minimumSize: const Size.fromHeight(50)),
            child: child,
          );
  }
}
