import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(
      text: Validators.isEmail(widget.initialEmail ?? '')
          ? widget.initialEmail
          : null);
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(authViewModelProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(authViewModelProvider.notifier)
        .sendPasswordReset(_email.text);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    return FormPage(
      title: 'Reset password',
      subtitle:
          'Enter your account email and we\'ll send you a link to choose a new password.',
      children: [
        if (_sent) ...[
          SentNotice(
            title: 'Check your inbox',
            message:
                'If an account exists for ${_email.text.trim()}, a reset link is on its way. '
                'It can take a minute; check spam too.',
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/login'),
            child: const Text('Back to sign in'),
          ),
        ] else
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(CupertinoIcons.at, size: 19),
                  ),
                  validator: (v) =>
                      Validators.isEmail((v ?? '').trim().toLowerCase())
                          ? null
                          : 'Please enter a valid email address',
                ),
                const SizedBox(height: 22),
                FormError(state.errorMessage),
                BusyButton(
                    label: 'Send reset link',
                    busy: state.isLoading,
                    onPressed: _submit),
              ],
            ),
          ),
      ],
    );
  }
}
