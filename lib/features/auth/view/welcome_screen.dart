import 'dart:ui';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
          ),
        );
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
