// test/widget/custom_search_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_management_system/core/widgets/custom_search_bar.dart';

class TestVSync extends TickerProvider {
  const TestVSync();
  
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void main() {
  group('CustomSearchBar', () {
    late AnimationController controller;

    setUp(() {
      controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: const TestVSync(),
      );
      // Start with animation at 1.0 to ensure widget is fully visible
      controller.value = 1.0;
      debugPrint('\n📱 Setting up test environment...');
    });

    tearDown(() {
      controller.dispose();
      debugPrint('🧹 Cleaning up test environment...\n');
    });

    testWidgets('handles text input', (WidgetTester tester) async {
      debugPrint('🧪 Testing text input handling...');
      String searchText = '';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomSearchBar(
            onChanged: (value) => searchText = value,
            hintText: 'Search',
            isVisible: true,
            animation: controller,
          ),
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'test search');
      debugPrint('✍️ Entered text: "test search"');
      
      expect(searchText, 'test search');
      debugPrint('✅ Text input test passed\n');
    });

    testWidgets('shows hint text when empty', (WidgetTester tester) async {
      debugPrint('🧪 Testing hint text display...');
      const hintText = 'Search here';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomSearchBar(
            onChanged: (_) {},
            hintText: hintText,
            isVisible: true,
            animation: controller,
          ),
        ),
      ));
      await tester.pump();

      expect(find.text(hintText), findsOneWidget);
      debugPrint('✅ Hint text test passed\n');
    });

    testWidgets('clears text when clear button is pressed', (WidgetTester tester) async {
      debugPrint('🧪 Testing clear button functionality...');
      final textController = TextEditingController(text: 'initial text');
      bool clearCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: Center(
            child: CustomSearchBar(
              onChanged: (_) {},
              hintText: 'Search',
              isVisible: true,
              animation: controller,
              controller: textController,
              onClear: () => clearCalled = true,
            ),
          ),
        ),
      ));
      await tester.pump();

      debugPrint('📝 Initial text: "${textController.text}"');
      
      // Find the clear button using IconButton finder
      final clearButton = find.byType(IconButton);
      expect(clearButton, findsOneWidget, reason: 'Clear button should be visible');
      
      // Tap the clear button with warnIfMissed: false to suppress the warning
      await tester.tap(clearButton, warnIfMissed: false);
      await tester.pump();

      debugPrint('🔄 Tapped clear button');
      debugPrint('📝 Text after clear: "${textController.text}"');
      
      expect(textController.text, isEmpty, reason: 'Text should be cleared');
      expect(clearCalled, isTrue, reason: 'onClear callback should be called');
      debugPrint('✅ Clear button test passed\n');
    });

    testWidgets('animates visibility changes', (WidgetTester tester) async {
      debugPrint('🧪 Testing animation visibility...');
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomSearchBar(
            onChanged: (_) {},
            hintText: 'Search',
            isVisible: true,
            animation: controller,
          ),
        ),
      ));
      await tester.pump();

      // Test visible state
      controller.value = 1.0;
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      debugPrint('✓ Search bar visible at animation value 1.0');

      // Test hidden state
      controller.value = 0.0;
      await tester.pump();
      final size = tester.getSize(find.byType(SizeTransition));
      expect(size.width, 0.0);
      debugPrint('✓ Search bar hidden at animation value 0.0');
      
      debugPrint('✅ Animation test passed\n');
    });

    testWidgets('uses internal controller when no controller provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomSearchBar(
            onChanged: (_) {},
            hintText: 'Search',
            isVisible: true,
            animation: controller,
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('respects theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: CustomSearchBar(
            onChanged: (_) {},
            hintText: 'Search',
            isVisible: true,
            animation: controller,
          ),
        ),
      ));

      final container = find.byType(Container);
      final decoration = tester.widget<Container>(container).decoration as BoxDecoration;
      
      // Verify the border color matches theme
      expect(decoration.border!.top.color.alpha, 179);
    });

    testWidgets('shows search icon', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomSearchBar(
            onChanged: (_) {},
            hintText: 'Search',
            isVisible: true,
            animation: controller,
          ),
        ),
      ));

      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}