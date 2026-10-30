import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/validators.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'auth_widgets.dart';
import 'google_sign_in.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

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
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(authViewModelProvider.notifier)
        .login(_email.text, _password.text);
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final state = ref.watch(authViewModelProvider);
    return FormPage(
      title: 'Welcome back',
      subtitle: 'Sign in to continue your preparation.',
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(CupertinoIcons.at, size: 19),
                  ),
                  validator: (v) =>
                      Validators.isEmail((v ?? '').trim().toLowerCase())
                          ? null
                          : 'Please enter a valid email address',
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _password,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Please enter your password'
                      : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password',
                        extra: _email.text.trim()),
                    child: const Text('Forgot password?'),
                  ),
                ),
                FormError(state.errorMessage),
                BusyButton(
                    label: 'Sign in',
                    busy: state.isLoading,
                    onPressed: _submit),
              ],
            ),
          ),
        ),
        const OrDivider(),
        const GoogleButton(),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => context.pushReplacement('/register'),
          style: TextButton.styleFrom(foregroundColor: a.inkMuted),
          child: const Text('New here? Create an account'),
        ),
      ],
    );
  }
}
