// test/widget/custom_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_management_system/core/widgets/custom_button.dart';

void main() {
  group('CustomButton', () {
    testWidgets('renders button with text', (WidgetTester tester) async {
      const buttonText = 'Test Button';
      bool buttonPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: CustomButton(
          text: buttonText,
          onPressed: () => buttonPressed = true,
          isLoading: false,
        ),
      ));

      expect(find.text(buttonText), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(CustomButton));
      expect(buttonPressed, true);
    });

    testWidgets('shows loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CustomButton(
          text: 'Test Button',
          onPressed: () {},
          isLoading: true,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Button'), findsNothing);
    });
  });
}