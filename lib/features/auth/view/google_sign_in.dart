import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/auth_viewmodel.dart';

/// Google sign-in shared by the welcome and login screens. Unregistered
/// accounts are sent to registration with their email prefilled.
Future<void> signInWithGoogle(BuildContext context, WidgetRef ref) async {
  final result =
      await ref.read(authViewModelProvider.notifier).loginWithGoogleNative();
  if (!context.mounted) return;

  switch (result.status) {
    case GoogleAuthStatus.authenticated:
      context.go('/home');
    case GoogleAuthStatus.notRegistered:
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This Google account is not registered yet. Complete registration to continue.'),
        duration: Duration(seconds: 4),
      ));
      context.push('/register', extra: {
        'email': result.email,
        'name': result.displayName,
      });
    case GoogleAuthStatus.error:
      final err = result.errorMessage ?? ref.read(authViewModelProvider).errorMessage;
      if (err != null && err.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    case GoogleAuthStatus.cancelled:
      break;
  }
}
