import 'package:flutter/material.dart';

/// Asks before leaving a test or quiz that has unsaved answers.
/// Returns true if the user chose to leave.
Future<bool> confirmLeaveTest(
  BuildContext context, {
  String title = 'Leave this test?',
  String message = 'Your answers so far will be lost.',
}) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Leave'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Keep going'),
        ),
      ],
    ),
  );
  return leave ?? false;
}
