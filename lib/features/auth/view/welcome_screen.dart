import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/social_button.dart';
import '../viewmodel/auth_viewmodel.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _showGoogleAccountDialog(
      BuildContext context, WidgetRef ref) async {
    final emailCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        ),
        title: const Row(
          children: [
            Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('Connect Google Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google/Gmail address to sign in and sync your candidate score:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'example@gmail.com',
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailCtrl.text.trim().toLowerCase();
              if (!email.endsWith('@gmail.com')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please enter a valid Gmail (@gmail.com) address'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              final success = await ref
                  .read(authViewModelProvider.notifier)
                  .loginWithGoogleAccount(email: email);
              if (success && context.mounted) {
                context.go('/home');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSocialLogin(
      BuildContext context, WidgetRef ref, String provider) async {
    final success = await ref
        .read(authViewModelProvider.notifier)
        .loginWithGoogleNative();
    if (success && context.mounted) {
      context.go('/home');
    } else if (context.mounted) {
      final err = ref.read(authViewModelProvider).errorMessage;
      if (err != null && err.isNotEmpty) {
        if (!kIsWeb && err.toLowerCase().contains('could not be completed')) {
          _showGoogleAccountDialog(context, ref);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with soft blur
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/forest_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Blur Overlay
          Container(
            color: Colors.black.withValues(alpha: 0.3),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: const SizedBox.expand(),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  const Spacer(),
                  // State Emblem Logo
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.s),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/state_emblem.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Welcome Title
                  Text(
                    AppStrings.welcome,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontSize: 36,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    AppStrings.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textWhite.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  // Action Buttons
                  SecondaryButton(
                    text: AppStrings.createAccount,
                    isOutlined: true,
                    borderColor: AppColors.textWhite,
                    textColor: AppColors.textWhite,
                    onPressed: () => context.push('/register'),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  SecondaryButton(
                    text: AppStrings.loginIn,
                    isOutlined: true,
                    borderColor: AppColors.textWhite,
                    textColor: AppColors.textWhite,
                    onPressed: () => context.push('/login'),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Social Login section
                  Text(
                    'Or Connect with Gmail',
                    style: TextStyle(
                      color: AppColors.textWhite.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  SocialButton(
                    type: SocialType.google,
                    onPressed: () => _handleSocialLogin(context, ref, 'google'),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
