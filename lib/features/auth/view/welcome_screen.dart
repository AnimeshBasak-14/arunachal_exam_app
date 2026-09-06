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

  Widget _buildAccountTile(
      BuildContext context, String name, String email, Color color) {
    final initials = name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .take(2)
        .join();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Text(
          initials.isEmpty ? 'G' : initials,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      title: Text(name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(email,
          style:
              const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      onTap: () => Navigator.pop(context, email),
    );
  }

  Future<String?> _showGoogleAccountChooser(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
          ),
          title: const Row(
            children: [
              Icon(Icons.account_circle_outlined,
                  color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'Choose an account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'to continue to Arunachal Exam Prep',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.m),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildAccountTile(context, 'Animesh Basak',
                          'basakanimesh16@gmail.com', Colors.teal),
                      const Divider(height: 1),
                      _buildAccountTile(context, 'Animesh Basak',
                          'basakanimesh49@gmail.com', Colors.blue),
                      const Divider(height: 1),
                      _buildAccountTile(context, 'COC DYSTOPIAN',
                          'amazonbose08@gmail.com', Colors.purple),
                      const Divider(height: 1),
                      _buildAccountTile(context, 'ANIMESH BASAK',
                          'animesh.cse.21@nitap.ac.in', Colors.orange),
                      const Divider(height: 1),
                      _buildAccountTile(context, 'ANIMESH BASAK',
                          'tourdelhikolkata@gmail.com', Colors.red),
                      const Divider(height: 1),
                      _buildAccountTile(context, 'ANIMESH BASAK',
                          'tourkgp2022@gmail.com', Colors.amber),
                      const Divider(height: 1),
                      _buildAccountTile(context, 'Animesh BASAK',
                          'internshipapply445@gmail.com', Colors.pink),
                      const Divider(height: 1),
                      _buildAccountTile(context, 'tournortheast',
                          'tournortheast182@gmail.com', Colors.indigo),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.add_circle_outline_rounded,
                            color: AppColors.textSecondary),
                        title: const Text('Use another account',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        onTap: () async {
                          final newMail = await _showAddAccountDialog(context);
                          if (newMail != null && context.mounted) {
                            Navigator.pop(context, newMail);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _showAddAccountDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign in with Gmail'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'example@gmail.com',
              labelText: 'Gmail Address',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.toLowerCase().endsWith('@gmail.com')) {
                  Navigator.pop(context, text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Only @gmail.com accounts are allowed'),
                        backgroundColor: AppColors.error),
                  );
                }
              },
              child: const Text('NEXT'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSocialLogin(
      BuildContext context, WidgetRef ref, String provider) async {
    final chosenEmail = await _showGoogleAccountChooser(context);
    if (chosenEmail != null) {
      final success = await ref
          .read(authViewModelProvider.notifier)
          .loginSocial(provider, email: chosenEmail);
      if (success && context.mounted) {
        context.go('/home');
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
