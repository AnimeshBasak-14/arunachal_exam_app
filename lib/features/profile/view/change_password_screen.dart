import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/user_model.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  String? _sentOtp;
  int _timerSeconds = 0;
  bool _isSendingOtp = false;
  Timer? _timer;

  @override
  void dispose() {
    _newPasswordController.dispose();
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
    setState(() {
      _isSendingOtp = true;
    });

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
              Icon(Icons.lock_reset_rounded,
                  color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Security Verification Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your 6-digit security code to update password is:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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

  Future<void> _submit() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    if (_formKey.currentState?.validate() ?? false) {
      if (_sentOtp == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please click "Request OTP" first to verify your identity'),
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

      // Update registry and save password
      final storage = ref.read(storageServiceProvider);
      await storage.updateRegisteredPassword(
          user.email, _newPasswordController.text);
      if (user.phone.isNotEmpty) {
        await storage.updateRegisteredPassword(
            user.phone, _newPasswordController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password set & saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    }
  }

  Future<bool> _checkHasExistingPassword(UserModel? user, StorageService storage) async {
    if (user == null) return false;
    final pwdEmail = await storage.getRegisteredPassword(user.email);
    if (pwdEmail != null) return true;
    if (user.phone.isNotEmpty) {
      final pwdPhone = await storage.getRegisteredPassword(user.phone);
      if (pwdPhone != null) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).user;
    final storage = ref.watch(storageServiceProvider);

    return FutureBuilder<bool>(
      future: _checkHasExistingPassword(user, storage),
      builder: (context, snapshot) {
        final hasExistingPassword = snapshot.data ?? false;
        final isGoogleAccount = user?.email.endsWith('candidate.google@gmail.com') == true ||
            (user?.email.endsWith('@gmail.com') == true && !hasExistingPassword);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(isGoogleAccount && !hasExistingPassword
            ? 'SET PASSWORD'
            : 'SET / RESET PASSWORD'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: AppColors.primary, size: 28),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isGoogleAccount && !hasExistingPassword
                                  ? 'Set password for ${user?.email}'
                                  : 'Update password for ${user?.email}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Verify with 6-digit OTP code to safely save your new password.',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                CustomTextField(
                  label: 'New Password',
                  controller: _newPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_open_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                CustomTextField(
                  label: 'Confirm New Password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_reset_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.m),

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
                                      : 'Request OTP',
                                  style: TextStyle(
                                    color: _timerSeconds > 0
                                        ? AppColors.textDisabled
                                        : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                PrimaryButton(
                  text: 'SAVE PASSWORD',
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
  }
}
