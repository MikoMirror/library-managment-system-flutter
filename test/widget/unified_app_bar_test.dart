// test/widget/unified_app_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_management_system/core/widgets/app_bar.dart';

void main() {
  group('UnifiedAppBar', () {
    testWidgets('renders with title', (WidgetTester tester) async {
      const titleText = 'Test Title';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: UnifiedAppBar(
            title: Text(titleText),
          ),
        ),
      ));

      expect(find.text(titleText), findsOneWidget);
    });

    testWidgets('renders with actions', (WidgetTester tester) async {
      final testIcon = Icons.settings;
      bool actionPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: UnifiedAppBar(
            actions: [
              IconButton(
                icon: Icon(testIcon),
                onPressed: () => actionPressed = true,
              ),
            ],
          ),
        ),
      ));

      expect(find.byIcon(testIcon), findsOneWidget);
      await tester.tap(find.byIcon(testIcon));
      expect(actionPressed, true);
    });

    testWidgets('renders with custom bottom widget', (WidgetTester tester) async {
      const bottomText = 'Bottom Widget';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: UnifiedAppBar(
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48.0),
              child: Container(
                child: const Text(bottomText),
              ),
            ),
          ),
        ),
      ));

      expect(find.text(bottomText), findsOneWidget);
    });
  });
}