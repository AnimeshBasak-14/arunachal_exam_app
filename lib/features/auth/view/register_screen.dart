import 'dart:async';
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

class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  final String? initialName;

  const RegisterScreen({
    super.key,
    this.initialEmail,
    this.initialName,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  String? _sentOtp;
  int _timerSeconds = 0;
  bool _isSendingOtp = false;
  Timer? _timer;
  bool _agreeTerms = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameController.text = widget.initialName!;
    }
    Future.microtask(() {
      if (mounted) {
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timerSeconds = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  void _sendOtp() {
    // Validate email/phone field
    final emailPhone = _emailController.text.trim();
    if (emailPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter Gmail or Phone number first to receive OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final clean = emailPhone.toLowerCase();
    final isGmail = clean.endsWith('@gmail.com');
    final isPhone = RegExp(r'^\d{10}$').hasMatch(clean);
    if (!isGmail && !isPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please enter a valid Gmail (@gmail.com) or a 10-digit Phone number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    // Simulate network latency then send OTP
    Future.delayed(const Duration(milliseconds: 400), () {
      final randomOtp =
          (100000 + (899999 * (DateTime.now().microsecond / 1000000)))
              .round()
              .toString();
      setState(() {
        _sentOtp = randomOtp;
        _isSendingOtp = false;
        _startTimer();
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXL)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded,
                  color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('OTP Verification Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your verification code for $emailPhone is:',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  randomOtp,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tap "Auto-fill Code" below to enter it automatically.',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _otpController.text = randomOtp;
                Navigator.pop(ctx);
              },
              child: const Text('Auto-fill Code',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1960, 1, 1),
      lastDate: DateTime.now()
          .subtract(const Duration(days: 365 * 5)), // at least 5 years old
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submit() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must agree to the Terms & Conditions'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_sentOtp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please request an OTP code first by clicking "Send OTP"'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authViewModelProvider.notifier).register(
            name: _nameController.text,
            emailOrPhone: _emailController.text,
            dob: _dobController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            otpEntered: _otpController.text.trim(),
            otpSent: _sentOtp!,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account registered successfully! Welcome 🎉'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        context.go('/home');
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    final result = await ref
        .read(authViewModelProvider.notifier)
        .loginWithGoogleNative();
    if (!mounted) return;

    if (result.status == GoogleAuthStatus.authenticated) {
      context.go('/home');
    } else if (result.status == GoogleAuthStatus.notRegistered) {
      setState(() {
        if (result.email != null && result.email!.isNotEmpty) {
          _emailController.text = result.email!;
        }
        if (result.displayName != null && result.displayName!.isNotEmpty) {
          _nameController.text = result.displayName!;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Google account connected! Please enter your DOB and password to complete registration.'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 4),
        ),
      );
    } else if (result.status == GoogleAuthStatus.error) {
      final err = result.errorMessage ??
          ref.read(authViewModelProvider).errorMessage;
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
                const SizedBox(height: AppSpacing.s),
                // Title
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
                  AppStrings.registerTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Input Fields
                CustomTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                // Email or Phone input
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

                // DOB Picker field
                GestureDetector(
                  onTap: () => _selectDob(context),
                  child: AbsorbPointer(
                    child: CustomTextField(
                      label: 'Date of Birth (DOB)',
                      controller: _dobController,
                      prefixIcon: Icons.calendar_month_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your Date of Birth';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // OTP Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        label: '6-digit OTP code',
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.security_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the OTP';
                          }
                          if (value.trim().length != 6) {
                            return 'Must be 6 digits';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _timerSeconds > 0 || _isSendingOtp
                              ? null
                              : _sendOtp,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _timerSeconds > 0
                                  ? AppColors.textDisabled
                                  : AppColors.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSendingOtp
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.primary),
                                )
                              : Text(
                                  _timerSeconds > 0
                                      ? '${_timerSeconds}s'
                                      : 'Send OTP',
                                  style: TextStyle(
                                    color: _timerSeconds > 0
                                        ? AppColors.textDisabled
                                        : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),

                CustomTextField(
                  label: AppStrings.password,
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.m),
                CustomTextField(
                  label: AppStrings.confirmPassword,
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                // Form Inline Error Display
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.s),
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
                  const SizedBox(height: AppSpacing.s),
                ],

                // Terms Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _agreeTerms = val ?? true;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        AppStrings.agreeTerms,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                // Action Button
                PrimaryButton(
                  text: 'CREATE ACCOUNT',
                  isLoading: state.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Text('·', style: TextStyle(color: AppColors.textHint)),
                    TextButton(
                      onPressed: () {
                        final emailPhone = _emailController.text.trim();
                        context.push(
                          '/forgot-password',
                          extra: emailPhone.isNotEmpty ? emailPhone : null,
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
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
