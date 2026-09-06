import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../viewmodel/auth_viewmodel.dart';

class GoogleAccountChooserDialog extends ConsumerStatefulWidget {
  const GoogleAccountChooserDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const GoogleAccountChooserDialog(),
    );
  }

  @override
  ConsumerState<GoogleAccountChooserDialog> createState() =>
      _GoogleAccountChooserDialogState();
}

class _GoogleAccountChooserDialogState
    extends ConsumerState<GoogleAccountChooserDialog> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showCustomInput = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectAccount(String email, {String? name, String? pic}) async {
    setState(() => _isSubmitting = true);
    final success = await ref
        .read(authViewModelProvider.notifier)
        .loginWithGoogleAccount(
          email: email,
          displayName: name,
          photoUrl: pic,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final savedAccounts = storage.getSavedAccounts();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: 440,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Google Brand Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.network(
                      'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                      width: 22,
                      height: 22,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_circle,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Choose an account for Arunachal Exam Prep',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 14),

            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 3),
                      SizedBox(height: 14),
                      Text('Signing in...',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else ...[
              // Saved Accounts on this browser / device
              if (savedAccounts.isNotEmpty && !_showCustomInput) ...[
                const Text(
                  'Saved Accounts on this Device',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: savedAccounts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    itemBuilder: (context, idx) {
                      final acc = savedAccounts[idx];
                      return _buildAccountTile(acc);
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Custom Input Form or Add Account toggle
              if (_showCustomInput) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Enter Google Account Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Google Email Address',
                          hintText: 'e.g. name@gmail.com',
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your Google email';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Display Name (Optional)',
                          hintText: 'e.g. Animesh Basak',
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (savedAccounts.isNotEmpty)
                            TextButton(
                              onPressed: () =>
                                  setState(() => _showCustomInput = false),
                              child: const Text('Back to saved'),
                            ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _selectAccount(
                                  _emailController.text.trim(),
                                  name: _nameController.text.trim(),
                                );
                              }
                            },
                            child: const Text('Continue'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Button to enter custom account
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _showCustomInput = true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: const Icon(Icons.person_add_alt_1_outlined,
                              size: 18, color: Color(0xFF4B5563)),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Use another Google account',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile(UserModel user) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _selectAccount(
        user.email,
        name: user.name,
        pic: user.profilePic,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'G',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
