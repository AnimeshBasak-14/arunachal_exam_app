import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  String? _sentOtp;
  int _timerSeconds = 0;
  bool _isSendingOtp = false;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
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
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !RegExp(r'^\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

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
              Icon(Icons.sms_outlined, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('SMS Verification Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your verification code for +91 $phone is:',
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

  Future<void> _submit() async {
    if (_sentOtp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please request verification OTP first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_otpController.text.trim() != _sentOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP code. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        final phone = _phoneController.text.trim();
        await ref.read(authViewModelProvider.notifier).updateProfile(
              name: user.name,
              email: user.email,
              phone: phone,
              profilePic: user.profilePic,
              dob: user.dob,
              rating: user.rating,
              city: user.city,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(phone);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('CHANGE PHONE NUMBER'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security_rounded,
                        color: AppColors.primary, size: 28),
                    SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone Number Security Verification',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primaryDark),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Updating your mobile number requires 6-digit OTP verification.',
                            style: TextStyle(
                                fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'New 10-Digit Mobile Number',
                      controller: _phoneController,
                      prefixIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter mobile number';
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                          return 'Please enter a valid 10-digit number';
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
                            prefixIcon: Icons.shield_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter OTP';
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
                                          strokeWidth: 2,
                                          color: AppColors.primary),
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
                      text: 'VERIFY & UPDATE PHONE',
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
