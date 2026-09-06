import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/social_button.dart';
import '../viewmodel/auth_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authViewModelProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
      if (success && mounted) {
        context.go('/home');
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    final success = await ref
        .read(authViewModelProvider.notifier)
        .loginWithGoogleNative();
    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
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
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.l),
                // Heading
                Text(
                  AppStrings.welcome,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 32,
                      ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  AppStrings.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                // Inputs
                CustomTextField(
                  label: 'Gmail or Phone number',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter Gmail or phone number';
                    }
                    final clean = value.trim().toLowerCase();
                    final isGmail = clean.endsWith('@gmail.com');
                    final isPhone = RegExp(r'^\d{10}$').hasMatch(clean);
                    if (!isGmail && !isPhone) {
                      return 'Only Gmail (@gmail.com) or 10-digit Phone numbers allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.m),
                CustomTextField(
                  label: AppStrings.password,
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),

                // Form Inline Error Display
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
                // Action Button
                PrimaryButton(
                  text: AppStrings.signIn,
                  isLoading: state.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.xxl),
                // Footer
                Text(
                  'Or Connect with Gmail',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(
                      type: SocialType.google,
                      onPressed: () => _handleSocialLogin('google'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
