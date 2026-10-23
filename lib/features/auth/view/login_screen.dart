import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'google_sign_in.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(authViewModelProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authViewModelProvider.notifier).login(_id.text, _password.text);
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final state = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(CupertinoIcons.back),
        ),
      ),
      body: AuraBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welcome back', style: AuraType.serif(32, a.ink)),
                  const SizedBox(height: 8),
                  Text('Sign in to continue your preparation.',
                      style: AuraType.sans(15, a.inkMuted)),
                  const SizedBox(height: 34),
                  TextFormField(
                    controller: _id,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
                    decoration: const InputDecoration(
                      labelText: 'Email or phone number',
                      prefixIcon: Icon(CupertinoIcons.at, size: 19),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter email or phone number';
                      final clean = v.trim().toLowerCase();
                      if (!Validators.isEmail(clean) && !Validators.isPhone(clean)) {
                        return Validators.invalidIdMessage;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(CupertinoIcons.lock, size: 19),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash, size: 19),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        final id = _id.text.trim();
                        context.push('/forgot-password', extra: id.isEmpty ? null : id);
                      },
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    child: state.errorMessage == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(state.errorMessage!,
                                style: AuraType.sans(13.5, a.danger, height: 1.45)),
                          ),
                  ),
                  FilledButton(
                    onPressed: state.isLoading ? null : _submit,
                    child: state.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: a.onAccent),
                          )
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: 22),
                  Row(children: [
                    Expanded(child: Divider(color: a.hairline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: AuraType.sans(12.5, a.inkFaint)),
                    ),
                    Expanded(child: Divider(color: a.hairline)),
                  ]),
                  const SizedBox(height: 22),
                  OutlinedButton(
                    onPressed: state.isLoading ? null : () => signInWithGoogle(context, ref),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('G', style: AuraType.sans(17, a.ink, weight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        const Text('Continue with Google'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () => context.pushReplacement('/register'),
                    style: TextButton.styleFrom(foregroundColor: a.inkMuted),
                    child: const Text('New here? Create an account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
