import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../auth/view/auth_widgets.dart';
import '../../../core/services/admin_session.dart';

/// Shows an admin sign-in form until [AdminSession] holds a valid admin token,
/// then renders [child].
class AdminGate extends StatefulWidget {
  final Widget child;
  const AdminGate({super.key, required this.child});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    String? err;
    try {
      err = await AdminSession.signIn(
          _emailController.text, _passwordController.text);
    } catch (e) {
      err = 'Network error. Please try again.';
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (AdminSession.isSignedIn) return widget.child;
    return FormPage(
      title: 'Admin sign-in',
      subtitle: 'For question editors only. Uses your Supabase admin account.',
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Admin email',
                  prefixIcon: Icon(CupertinoIcons.at, size: 19),
                ),
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _passwordController,
                action: TextInputAction.done,
                onSubmitted: (_) => _loading ? null : _submit(),
              ),
              const SizedBox(height: 22),
              FormError(_error),
              BusyButton(label: 'Sign in', busy: _loading, onPressed: _submit),
            ],
          ),
        ),
      ],
    );
  }
}
