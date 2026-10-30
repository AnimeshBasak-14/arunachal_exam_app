import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../auth/view/auth_widgets.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(authViewModelProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(authViewModelProvider.notifier)
        .changePassword(_current.text, _next.text, _confirm.text);
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Password updated.')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final vm = ref.read(authViewModelProvider.notifier);
    final state = ref.watch(authViewModelProvider);

    if (!vm.hasPassword) {
      return FormPage(
        title: 'Password',
        children: [
          GlassCard(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(CupertinoIcons.info, color: a.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You sign in with Google, so there\'s no separate password to change. '
                  'Manage it from your Google account.',
                  style: AuraType.sans(14.5, a.inkMuted, height: 1.5),
                ),
              ),
            ]),
          ),
        ],
      );
    }

    return FormPage(
      title: 'Change password',
      subtitle:
          'Use at least 8 characters. You\'ll stay signed in on this phone.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(
                controller: _current,
                label: 'Current password',
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Enter your current password' : null,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _next,
                label: 'New password',
                newPassword: true,
                validator: (v) =>
                    (v ?? '').length < 8 ? 'At least 8 characters' : null,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirm,
                label: 'Confirm new password',
                newPassword: true,
                action: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    v != _next.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 22),
              FormError(state.errorMessage),
              BusyButton(
                  label: 'Update password',
                  busy: state.isLoading,
                  onPressed: _submit),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    context.push('/forgot-password', extra: state.user?.email),
                child: const Text('Forgot your current password?'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
