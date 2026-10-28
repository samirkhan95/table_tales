import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:table_tales/models/photo.dart';
import 'package:table_tales/models/restaurant.dart';
import 'package:table_tales/models/visit.dart';
import 'package:table_tales/providers/restaurant_provider.dart';
import 'package:table_tales/providers/settings_provider.dart';
import 'package:table_tales/screens/timeline_screen.dart';
import 'package:table_tales/utils/currency_formatter.dart';
import 'package:table_tales/utils/date_formatter.dart';
import 'package:table_tales/widgets/scrapbook_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Our Story Logic & Formatters', () {
    test('CurrencyFormatter formats amount and price range correctly', () {
      expect(CurrencyFormatter.formatPriceRange(3), equals('\$\$\$'));
      expect(CurrencyFormatter.formatAmount(42.50, currency: '\$'), equals('\$42.50'));
      expect(CurrencyFormatter.formatAmount(null), equals(''));
    });

    test('DateFormatter parses calendar dates without timezone shifting', () {
      final parsed = DateFormatter.parseCompact('2023-09-12');
      expect(parsed, isNotNull);
      expect(parsed!.year, equals(2023));
      expect(parsed.month, equals(9));
      expect(parsed.day, equals(12));
    });

    test('ScrapbookCard maps occasion to romantic emojis correctly', () {
      expect(ScrapbookCard.getOccasionEmoji('Anniversary Celebration'), equals('🥂'));
      expect(ScrapbookCard.getOccasionEmoji('Romantic Date Night'), equals('❤️'));
      expect(ScrapbookCard.getOccasionEmoji('Birthday Dinner'), equals('🎂'));
      expect(ScrapbookCard.getOccasionEmoji('Casual Brunch'), equals('☕'));
      expect(ScrapbookCard.getOccasionEmoji('Trip to Paris'), equals('✈️'));
      expect(ScrapbookCard.getOccasionEmoji(null), isNull);
    });

    test('Multiple visits to same restaurant have distinct sequence numbers', () {
      final rId = 'rest-123';
      final v1 = Visit(
        id: 'v1',
        restaurantId: rId,
        visitDate: DateTime(2022, 5, 10),
        notes: 'First time here',
      );
      final v2 = Visit(
        id: 'v2',
        restaurantId: rId,
        visitDate: DateTime(2023, 8, 15),
        notes: 'Second visit for anniversary',
      );
      final v3 = Visit(
        id: 'v3',
        restaurantId: rId,
        visitDate: DateTime(2024, 1, 20),
        notes: 'Third visit',
      );

      final visits = [v3, v1, v2]; // unsorted input

      int getSequence(Visit v, List<Visit> all) {
        final rVisits = all.where((item) => item.restaurantId == v.restaurantId).toList();
        rVisits.sort((a, b) {
          if (a.visitDate == null && b.visitDate == null) return a.createdAt.compareTo(b.createdAt);
          if (a.visitDate == null) return 1;
          if (b.visitDate == null) return -1;
          return a.visitDate!.compareTo(b.visitDate!);
        });
        return rVisits.indexWhere((item) => item.id == v.id) + 1;
      }

      expect(getSequence(v1, visits), equals(1));
      expect(getSequence(v2, visits), equals(2));
      expect(getSequence(v3, visits), equals(3));
    });

    test('Undated visits are handled safely without crashing', () {
      final v = Visit(restaurantId: 'r1', visitDate: null, notes: 'Memory from early days');
      expect(v.visitDate, isNull);
      expect(DateFormatter.formatShort(v.visitDate), equals('Unknown'));
    });
  });

  group('ScrapbookCard Widget Tests', () {
    testWidgets('ScrapbookCard renders date badge, title, notes, and 3-photo strip with +N overlay', (tester) async {
      final restaurant = Restaurant(
        id: 'r1',
        name: 'Osteria Bella Vista',
        location: 'Seaside Pier',
        cuisine: 'Italian',
      );

      final visit = Visit(
        id: 'v1',
        restaurantId: 'r1',
        visitDate: DateTime(2023, 9, 12, 19, 30),
        occasion: 'Date Night',
        notes: 'Today was an extraordinary day filled with adventure and discovery.',
        rating: 4.9,
      );

      final photos = [
        Photo(id: 'p1', restaurantId: 'r1', visitId: 'v1', filePath: 'test1.jpg'),
        Photo(id: 'p2', restaurantId: 'r1', visitId: 'v1', filePath: 'test2.jpg'),
        Photo(id: 'p3', restaurantId: 'r1', visitId: 'v1', filePath: 'test3.jpg'),
        Photo(id: 'p4', restaurantId: 'r1', visitId: 'v1', filePath: 'test4.jpg'),
        Photo(id: 'p5', restaurantId: 'r1', visitId: 'v1', filePath: 'test5.jpg'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScrapbookCard(
                visit: visit,
                restaurant: restaurant,
                photos: photos,
                visitSequence: 2,
                totalVisits: 3,
                index: 0,
                enableTilt: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Verify day number "12"
      expect(find.text('12'), findsOneWidget);
      // Verify month/year "Sep 2023"
      expect(find.text('Sep 2023'), findsOneWidget);
      // Verify day of week "Tuesday" and visit sequence
      expect(find.textContaining('Tuesday'), findsOneWidget);
      expect(find.textContaining('Visit #2'), findsOneWidget);
      // Verify restaurant title
      expect(find.text('Osteria Bella Vista'), findsOneWidget);
      // Verify occasion badge
      expect(find.text('Date Night'), findsOneWidget);
      // Verify visit note
      expect(find.textContaining('Today was an extraordinary day'), findsOneWidget);
      // Verify +3 overlay for remaining photos (5 total - 2 first thumbnails = +3 on the 3rd)
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('ScrapbookCard renders without overflow on narrow 320px mobile screen', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final restaurant = Restaurant(
        id: 'r2',
        name: 'Very Long Restaurant Name That Might Wrap On Narrow Screens',
        location: 'Downtown Center Plaza',
      );

      final visit = Visit(
        id: 'v2',
        restaurantId: 'r2',
        visitDate: DateTime(2024, 2, 14),
        occasion: 'Valentine Dinner',
        notes: 'Delicious multi-course chef tasting menu.',
      );

      final photos = [
        Photo(id: 'p1', restaurantId: 'r2', filePath: 'p1.jpg'),
        Photo(id: 'p2', restaurantId: 'r2', filePath: 'p2.jpg'),
        Photo(id: 'p3', restaurantId: 'r2', filePath: 'p3.jpg'),
        Photo(id: 'p4', restaurantId: 'r2', filePath: 'p4.jpg'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScrapbookCard(
                visit: visit,
                restaurant: restaurant,
                photos: photos,
                visitSequence: 1,
                totalVisits: 1,
                index: 1,
                enableTilt: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Feb 2024'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
    });
  });

  group('TimelineScreen Our Story UI', () {
    testWidgets('TimelineScreen displays Our Story title and romantic subtitle', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RestaurantProvider>(create: (_) => RestaurantProvider()),
            ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
          ],
          child: const MaterialApp(
            home: TimelineScreen(showBackButton: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Our Story'), findsOneWidget);
      expect(find.text('Every place, a story. Every visit, a memory.'), findsOneWidget);
      // Back button is present because showBackButton = true
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      // Search toggle button is present
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });
  });
}
