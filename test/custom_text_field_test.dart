import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arunachal_exam_app/core/widgets/custom_text_field.dart';

void main() {
  testWidgets(
      'CustomTextField password field shows tooltip and toggles obscure text',
      (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            label: 'Password',
            controller: controller,
            isPassword: true,
          ),
        ),
      ),
    );

    // Initial state: obscureText is true, tooltip is 'Show password'
    expect(find.byType(IconButton), findsOneWidget);
    final iconButtonFinder = find.byType(IconButton);
    final IconButton iconButtonWidget = tester.widget(iconButtonFinder);
    expect(iconButtonWidget.tooltip, 'Show password');

    // Tap to show password
    await tester.tap(iconButtonFinder);
    await tester.pump();

    // Toggled state: tooltip is 'Hide password'
    final IconButton toggledIconButtonWidget = tester.widget(iconButtonFinder);
    expect(toggledIconButtonWidget.tooltip, 'Hide password');
  });
}
