import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:table_tales/models/app_settings.dart';
import 'package:table_tales/models/photo.dart';
import 'package:table_tales/models/restaurant.dart';
import 'package:table_tales/models/visit.dart';
import 'package:table_tales/services/data_backup_service.dart';
import 'package:table_tales/services/database_service.dart';
import 'package:table_tales/services/photo_storage_service.dart';
import 'package:table_tales/utils/date_formatter.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory testDocsDir;

  setUpAll(() {
    testDocsDir = Directory.systemTemp.createTempSync('table_tales_test_docs_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return testDocsDir.path;
      },
    );
  });

  tearDownAll(() {
    try {
      if (testDocsDir.existsSync()) {
        testDocsDir.deleteSync(recursive: true);
      }
    } catch (_) {
      // Windows lock cleanup tolerance
    }
  });

  group('Restaurant & Visit Models', () {
    test('Restaurant model normalizes names correctly', () {
      final r = Restaurant(name: '  Osteria   Francescana  ');
      expect(r.normalizedName, equals('osteria francescana'));
    });

    test('Restaurant toMap and fromMap roundtrip', () {
      final r = Restaurant(
        name: 'Sakura Ramen',
        location: 'Downtown',
        cuisine: 'Japanese',
        priceRange: 2,
        isFavorite: true,
        tags: ['Ramen', 'DateNight'],
      );

      final map = r.toMap();
      final restored = Restaurant.fromMap(map);

      expect(restored.id, equals(r.id));
      expect(restored.name, equals('Sakura Ramen'));
      expect(restored.location, equals('Downtown'));
      expect(restored.cuisine, equals('Japanese'));
      expect(restored.priceRange, equals(2));
      expect(restored.isFavorite, isTrue);
      expect(restored.tags, containsAll(['Ramen', 'DateNight']));
    });

    test('Visit model supports approximate date and spent amounts', () {
      final v = Visit(
        restaurantId: 'r1',
        visitDate: DateTime(2024, 10, 15),
        isApproximateDate: true,
        amountSpent: 85.50,
        currency: '\$',
        mealType: 'Dinner',
        rating: 4.8,
      );

      final json = v.toJson();
      final restored = Visit.fromJson(json);

      expect(restored.restaurantId, equals('r1'));
      expect(restored.isApproximateDate, isTrue);
      expect(restored.amountSpent, equals(85.50));
      expect(restored.rating, equals(4.8));
    });
  });

  group('Date Formatter', () {
    test('Formats date ISO compact correctly', () {
      final dt = DateTime(2024, 5, 20);
      expect(DateFormatter.formatCompact(dt), equals('2024-05-20'));
    });

    test('Parses compact date safely without timezone shift', () {
      final parsed = DateFormatter.parseCompact('2024-05-20');
      expect(parsed?.year, equals(2024));
      expect(parsed?.month, equals(5));
      expect(parsed?.day, equals(20));
    });
  });

  group('DataBackupService Export & Restore', () {
    late DatabaseService dbService;
    late DataBackupService backupService;

    setUp(() async {
      dbService = DatabaseService();
      backupService = DataBackupService();
      await dbService.clearAllData();
    });

    tearDown(() async {
      await dbService.clearAllData();
    });

    test('exportToJson embeds photo files as base64 and exports all dates & visits', () async {
      // 1. Create a dummy photo file on disk in table_tales_photos directory
      final photosDir = await PhotoStorageService.getPhotosDirectoryPath();
      final testPhotoFile = File(p.join(photosDir, 'test_cover.jpg'));
      final dummyBytes = utf8.encode('fake_image_bytes_12345');
      await testPhotoFile.writeAsBytes(dummyBytes);

      // 2. Add restaurant with cover photo
      final r = Restaurant(
        id: 'rest-1',
        name: 'The French Laundry',
        location: 'Yountville, CA',
        cuisine: 'French',
        priceRange: 4,
        coverPhotoPath: testPhotoFile.path,
      );
      await dbService.insertRestaurant(r);

      // 3. Add visit with specific date & time
      final visitDate = DateTime(2026, 10, 24, 19, 30);
      final v = Visit(
        id: 'visit-1',
        restaurantId: r.id,
        visitDate: visitDate,
        mealType: 'Dinner',
        occasion: 'Anniversary',
        rating: 5.0,
        amountSpent: 350.0,
      );
      await dbService.insertVisit(v);

      // 4. Add gallery photo
      final p1 = Photo(
        id: 'photo-1',
        restaurantId: r.id,
        visitId: v.id,
        filePath: testPhotoFile.path,
        caption: 'Signature Dish',
      );
      await dbService.insertPhoto(p1);

      // 5. Export to JSON
      final jsonStr = await backupService.exportToJson(
        settings: const AppSettings(coupleNames: 'Romeo & Juliet'),
      );

      final Map<String, dynamic> exported = jsonDecode(jsonStr);
      expect(exported['version'], equals('2.0'));
      expect(exported['app'], equals('TableTales'));
      expect(exported['restaurants'], hasLength(1));
      expect(exported['visits'], hasLength(1));
      expect(exported['photos'], hasLength(1));

      // Check date preserved
      final visitJson = exported['visits'][0];
      expect(DateTime.parse(visitJson['visitDate']), equals(visitDate));

      // Check photo binary embedded
      final photoFiles = exported['photoFiles'] as Map<String, dynamic>;
      expect(photoFiles.containsKey('test_cover.jpg'), isTrue);
      expect(photoFiles['test_cover.jpg'], equals(base64Encode(dummyBytes)));

      // 6. Test inspectBackup
      final preview = await backupService.inspectBackup(jsonStr);
      expect(preview.isValid, isTrue);
      expect(preview.restaurantsCount, equals(1));
      expect(preview.visitsCount, equals(1));
      expect(preview.photosCount, equals(1));
      expect(preview.photoFilesCount, equals(1));
      expect(preview.coupleNames, equals('Romeo & Juliet'));

      // 7. Test importFromJson with clean restore (simulating data loss recovery)
      await dbService.clearAllData();
      final emptyR = await dbService.getAllRestaurants();
      expect(emptyR, isEmpty);

      // Delete the photo file on disk to simulate lost app data
      if (await testPhotoFile.exists()) {
        await testPhotoFile.delete();
      }
      expect(await testPhotoFile.exists(), isFalse);

      // Now restore from the backup JSON
      final report = await backupService.importFromJson(jsonStr, clearExisting: true);
      expect(report.restaurantsImported, equals(1));
      expect(report.visitsImported, equals(1));
      expect(report.photosImported, equals(1));
      expect(report.photoFilesRestored, equals(1));
      expect(report.restoredSettings?.coupleNames, equals('Romeo & Juliet'));

      // Verify photo file was restored back onto disk
      expect(await testPhotoFile.exists(), isTrue);
      final restoredBytes = await testPhotoFile.readAsBytes();
      expect(restoredBytes, equals(dummyBytes));

      // Verify database records restored
      final restoredRestaurants = await dbService.getAllRestaurants();
      expect(restoredRestaurants, hasLength(1));
      expect(restoredRestaurants.first.name, equals('The French Laundry'));

      final restoredVisits = await dbService.getAllVisits();
      expect(restoredVisits, hasLength(1));
      expect(restoredVisits.first.visitDate, equals(visitDate));
      expect(restoredVisits.first.rating, equals(5.0));

      final restoredPhotos = await dbService.getAllPhotos();
      expect(restoredPhotos, hasLength(1));
      expect(restoredPhotos.first.caption, equals('Signature Dish'));
    });
  });
}
