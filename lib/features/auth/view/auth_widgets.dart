import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';

/// Page frame shared by the sign-in, account and profile forms: back button,
/// serif title, quiet subtitle, then the form.
class FormPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  const FormPage(
      {super.key, required this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return AuraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/welcome'),
            icon: const Icon(CupertinoIcons.back),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: AuraType.serif(32, a.ink, height: 1.15)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(subtitle!,
                          style: AuraType.sans(15, a.inkMuted, height: 1.5)),
                    ],
                    const SizedBox(height: 30),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Password field with a show/hide toggle.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  final bool newPassword;
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.action = TextInputAction.next,
    this.onSubmitted,
    this.newPassword = false,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        textInputAction: widget.action,
        onFieldSubmitted: widget.onSubmitted,
        autofillHints: [
          widget.newPassword
              ? AutofillHints.newPassword
              : AutofillHints.password
        ],
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(CupertinoIcons.lock, size: 19),
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                size: 19),
          ),
        ),
        validator: widget.validator,
      );
}

/// Error text that slides in under a form.
class FormError extends StatelessWidget {
  final String? message;
  const FormError(this.message, {super.key});

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 220),
        child: message == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(message!,
                    style:
                        AuraType.sans(13.5, context.aura.danger, height: 1.45)),
              ),
      );
}

/// Primary button that shows a spinner while [busy].
class BusyButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  final bool danger;
  const BusyButton(
      {super.key,
      required this.label,
      required this.busy,
      this.onPressed,
      this.danger = false});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return FilledButton(
      style: danger
          ? FilledButton.styleFrom(
              backgroundColor: a.danger, foregroundColor: Colors.white)
          : null,
      onPressed: busy ? null : onPressed,
      child: busy
          ? SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: a.onAccent),
            )
          : Text(label),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(children: [
        Expanded(child: Divider(color: a.hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: AuraType.sans(12.5, a.inkFaint)),
        ),
        Expanded(child: Divider(color: a.hairline)),
      ]),
    );
  }
}

/// Confirmation panel shown after an email is sent.
class SentNotice extends StatelessWidget {
  final String title;
  final String message;
  const SentNotice({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.envelope_badge, color: a.accent),
          const SizedBox(height: 12),
          Text(title, style: AuraType.sans(16, a.ink, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(message, style: AuraType.sans(14, a.inkMuted, height: 1.5)),
        ],
      ),
    );
  }
}
