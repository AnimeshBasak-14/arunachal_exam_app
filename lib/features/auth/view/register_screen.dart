import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/validators.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'auth_widgets.dart';
import 'google_sign_in.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  final String? initialName;
  const RegisterScreen({super.key, this.initialEmail, this.initialName});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
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
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authViewModelProvider.notifier).register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          confirmPassword: _confirm.text,
        );
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Welcome! We sent a verification link to ${_email.text.trim()}.'),
    ));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final state = ref.watch(authViewModelProvider);
    return FormPage(
      title: 'Create your account',
      subtitle: 'Your progress, saved cards and test history follow you to any phone.',
      children: [
        const GoogleButton(),
        const OrDivider(),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(CupertinoIcons.person, size: 19),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(CupertinoIcons.at, size: 19),
                  ),
                  validator: (v) => Validators.isEmail((v ?? '').trim().toLowerCase())
                      ? null
                      : 'Please enter a valid email address',
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _password,
                  newPassword: true,
                  validator: (v) => (v ?? '').length < 8 ? 'At least 8 characters' : null,
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _confirm,
                  label: 'Confirm password',
                  newPassword: true,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 22),
                FormError(state.errorMessage),
                BusyButton(label: 'Create account', busy: state.isLoading, onPressed: _submit),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => context.pushReplacement('/login'),
          style: TextButton.styleFrom(foregroundColor: a.inkMuted),
          child: const Text('Already have an account? Sign in'),
        ),
      ],
    );
  }
}
