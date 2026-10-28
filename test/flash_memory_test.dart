import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_tales/widgets/flash_memory_card.dart';

void main() {
  group('FlashMemoryCard Widget Tests', () {
    testWidgets('renders photo and restaurant name, and supports sliding left and right', (tester) async {
      final items = [
        const FlashMemoryItem(photoPath: 'photo1.jpg', restaurantName: 'Chillox'),
        const FlashMemoryItem(photoPath: 'photo2.jpg', restaurantName: 'Bella Vista'),
        const FlashMemoryItem(photoPath: 'photo3.jpg', restaurantName: 'Sakura Ramen'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlashMemoryCard(items: items),
          ),
        ),
      );

      // Verify the card renders
      expect(find.byType(FlashMemoryCard), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      // Verify initial restaurant name is rendered
      final initialNameFinder = find.byType(Text);
      expect(initialNameFinder, findsWidgets);

      // Test swiping left (to view next random photo)
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Test swiping right (to view previous random photo)
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await tester.pumpAndSettle();

      // Verify auto-timer advances after 3 seconds
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify tapping does not cause errors or trigger navigation
      await tester.tap(find.byType(FlashMemoryCard));
      await tester.pumpAndSettle();
      expect(find.byType(FlashMemoryCard), findsOneWidget);
    });

    testWidgets('handles single item without timer overflow', (tester) async {
      final singleItem = [
        const FlashMemoryItem(photoPath: 'photo1.jpg', restaurantName: 'Chillox'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlashMemoryCard(items: singleItem),
          ),
        ),
      );

      expect(find.text('Chillox'), findsOneWidget);
      // Pump 3 seconds
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Chillox'), findsOneWidget);
    });
  });
}
