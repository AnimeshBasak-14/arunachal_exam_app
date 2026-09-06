import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../viewmodel/auth_viewmodel.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmailOrPhone;

  const ForgotPasswordScreen({super.key, this.initialEmailOrPhone});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _sentOtp;
  int _timerSeconds = 0;
  bool _isSendingOtp = false;
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialEmailOrPhone != null &&
          widget.initialEmailOrPhone!.isNotEmpty) {
        _emailPhoneController.text = widget.initialEmailOrPhone!;
      } else {
        final currentUser = ref.read(authViewModelProvider).user;
        if (currentUser != null) {
          _emailPhoneController.text = currentUser.email.isNotEmpty
              ? currentUser.email
              : currentUser.phone;
        }
      }
    });
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _sendOtp() async {
    final rawInput = _emailPhoneController.text.trim();
    if (rawInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your registered Gmail or Phone number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cleanInput = rawInput.toLowerCase();
    final isGmail = cleanInput.endsWith('@gmail.com');
    final isPhone = RegExp(r'^\d{10}$').hasMatch(cleanInput);

    if (!isGmail && !isPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter a valid Gmail (@gmail.com) or 10-digit Phone'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    final storage = ref.read(storageServiceProvider);
    final registeredPwd = await storage.getRegisteredPassword(cleanInput);
    final registeredName = storage.getRegisteredName(cleanInput);

    bool accountExists = registeredPwd != null || registeredName != null;
    if (!accountExists && isGmail) {
      try {
        final firebase = ref.read(firebaseServiceProvider);
        final remoteUser = await firebase.fetchUserProfile(cleanInput);
        if (remoteUser != null) {
          accountExists = true;
        }
      } catch (_) {}
    }

    final loggedInUser = ref.read(authViewModelProvider).user;
    if (loggedInUser != null &&
        (loggedInUser.email.toLowerCase() == cleanInput ||
            loggedInUser.phone == cleanInput)) {
      accountExists = true;
    }

    if (!accountExists) {
      setState(() {
        _isSendingOtp = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No account found with this Gmail or Phone. Please register first.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final randomOtp =
        (100000 + Random().nextInt(900000)).toString();

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
            Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Verification OTP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your 6-digit password reset code for $cleanInput is:',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              'Valid for this password reset session only.',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
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
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cleanInput = _emailPhoneController.text.trim().toLowerCase();

    if (_sentOtp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap "Request OTP" first to verify your account'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_otpController.text.trim() != _sentOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP code. Verification failed.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final storage = ref.read(storageServiceProvider);
    final newPassword = _newPasswordController.text;

    // Update password in storage
    await storage.updateRegisteredPassword(cleanInput, newPassword);

    final currentUser = ref.read(authViewModelProvider).user;
    if (currentUser != null &&
        (currentUser.email.toLowerCase() == cleanInput ||
            currentUser.phone == cleanInput)) {
      if (currentUser.email.isNotEmpty && currentUser.email.toLowerCase() != cleanInput) {
        await storage.updateRegisteredPassword(currentUser.email, newPassword);
      }
      if (currentUser.phone.isNotEmpty && currentUser.phone != cleanInput) {
        await storage.updateRegisteredPassword(currentUser.phone, newPassword);
      }
    }

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset successfully! You can now log in.'),
        backgroundColor: AppColors.success,
      ),
    );

    if (currentUser != null) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forgot Password',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                // Icon Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Reset Your Password',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Enter your registered Gmail or Phone number. We will send a secure verification code to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Email / Phone Field
                CustomTextField(
                  label: 'Registered Gmail or Phone number',
                  controller: _emailPhoneController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter Gmail or Phone number';
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

                // OTP Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: '6-digit OTP Code',
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.pin_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the OTP';
                          }
                          if (value.trim().length != 6) {
                            return 'OTP must be 6 digits';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_timerSeconds > 0 || _isSendingOtp)
                            ? null
                            : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusM),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: _isSendingOtp
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                _timerSeconds > 0
                                    ? '${_timerSeconds}s'
                                    : 'Request OTP',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),

                // New Password
                CustomTextField(
                  label: 'New Password (min 6 chars)',
                  controller: _newPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                // Confirm Password
                CustomTextField(
                  label: 'Confirm New Password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Reset Password Button
                PrimaryButton(
                  text: 'RESET PASSWORD',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.l),

                // Back to Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Remember your password?',
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
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
