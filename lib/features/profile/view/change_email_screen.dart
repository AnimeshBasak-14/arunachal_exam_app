import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  String? _sentOtp;
  int _timerSeconds = 0;
  bool _isSendingOtp = false;
  Timer? _timer;

  @override
  void dispose() {
    _emailController.dispose();
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
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.toLowerCase().endsWith('@gmail.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Gmail (@gmail.com) address first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      final randomOtp = (100000 + (899999 * (DateTime.now().microsecond / 1000000))).round().toString();
      setState(() {
        _sentOtp = randomOtp;
        _isSendingOtp = false;
        _startTimer();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('[OTP Verification] Code sent to $email: $randomOtp.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 8),
        ),
      );
    });
  }

  Future<void> _connectWithGoogle() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      Navigator.pop(context); // Pop loading dialog
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        final gmail = 'candidate.google@gmail.com';
        await ref.read(authViewModelProvider.notifier).updateProfile(
              name: user.name,
              email: gmail,
              phone: user.phone,
              profilePic: user.profilePic,
              dob: user.dob,
              rating: user.rating,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected with Google successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(gmail);
      }
    }
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
        final gmail = _emailController.text.trim().toLowerCase();
        await ref.read(authViewModelProvider.notifier).updateProfile(
              name: user.name,
              email: gmail,
              phone: user.phone,
              profilePic: user.profilePic,
              dob: user.dob,
              rating: user.rating,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gmail address updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(gmail);
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
        title: const Text('CHANGE GMAIL'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Google connection card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    children: [
                      const Icon(Icons.link_rounded, size: 40, color: AppColors.primary),
                      const SizedBox(height: AppSpacing.s),
                      const Text(
                        'Fast Verification',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Automatically verify and update by linking your Google account',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      ElevatedButton.icon(
                        onPressed: _connectWithGoogle,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: const Text('Connect with Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              
              const Text(
                'OR UPDATE GMAIL MANUALLY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.m),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      label: 'New Gmail Address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter Gmail';
                        }
                        if (!value.trim().toLowerCase().endsWith('@gmail.com')) {
                          return 'Only Gmail (@gmail.com) allowed';
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
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _timerSeconds > 0 || _isSendingOtp ? null : _sendOtp,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _timerSeconds > 0 ? AppColors.textDisabled : AppColors.primary,
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
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    )
                                  : Text(
                                      _timerSeconds > 0 ? '${_timerSeconds}s' : 'Request OTP',
                                      style: TextStyle(
                                        color: _timerSeconds > 0 ? AppColors.textDisabled : AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    
                    PrimaryButton(
                      text: 'VERIFY & SAVE GMAIL',
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
