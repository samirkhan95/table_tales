import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/restaurant.dart';
import '../models/visit.dart';
import '../models/photo.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = 'table_tales.db';
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      path = p.join(docsDir.path, 'table_tales.db');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE restaurants (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        normalizedName TEXT NOT NULL,
        location TEXT,
        cuisine TEXT,
        mapsUrl TEXT,
        website TEXT,
        phone TEXT,
        priceRange INTEGER,
        coverPhotoPath TEXT,
        description TEXT,
        tags TEXT,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        isArchived INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE visits (
        id TEXT PRIMARY KEY,
        restaurantId TEXT NOT NULL,
        visitDate TEXT,
        isApproximateDate INTEGER NOT NULL DEFAULT 0,
        mealType TEXT,
        occasion TEXT,
        notes TEXT,
        rating REAL,
        amountSpent REAL,
        currency TEXT,
        tags TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (restaurantId) REFERENCES restaurants (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        restaurantId TEXT NOT NULL,
        visitId TEXT,
        filePath TEXT NOT NULL,
        caption TEXT,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (restaurantId) REFERENCES restaurants (id) ON DELETE CASCADE,
        FOREIGN KEY (visitId) REFERENCES visits (id) ON DELETE CASCADE
      )
    ''');

    // Create Indexes for fast querying & search
    await db.execute('CREATE INDEX idx_restaurants_normalizedName ON restaurants (normalizedName)');
    await db.execute('CREATE INDEX idx_restaurants_isFavorite ON restaurants (isFavorite)');
    await db.execute('CREATE INDEX idx_visits_restaurantId ON visits (restaurantId)');
    await db.execute('CREATE INDEX idx_visits_visitDate ON visits (visitDate)');
    await db.execute('CREATE INDEX idx_photos_restaurantId ON photos (restaurantId)');
    await db.execute('CREATE INDEX idx_photos_visitId ON photos (visitId)');
  }

  // --- RESTAURANT CRUD ---

  Future<List<Restaurant>> getAllRestaurants() async {
    final db = await database;
    final maps = await db.query('restaurants', where: 'isArchived = 0', orderBy: 'name ASC');
    return maps.map((map) => Restaurant.fromMap(map)).toList();
  }

  Future<Restaurant?> getRestaurantById(String id) async {
    final db = await database;
    final maps = await db.query('restaurants', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Restaurant.fromMap(maps.first);
  }

  Future<Restaurant?> findSimilarRestaurant(String name, {String? location}) async {
    final db = await database;
    final norm = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final maps = await db.query(
      'restaurants',
      where: 'normalizedName = ? AND isArchived = 0',
      whereArgs: [norm],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Restaurant.fromMap(maps.first);
    }
    return null;
  }

  Future<void> insertRestaurant(Restaurant restaurant) async {
    final db = await database;
    await db.insert('restaurants', restaurant.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateRestaurant(Restaurant restaurant) async {
    final db = await database;
    await db.update(
      'restaurants',
      restaurant.toMap(),
      where: 'id = ?',
      whereArgs: [restaurant.id],
    );
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('photos', where: 'restaurantId = ?', whereArgs: [restaurantId]);
      await txn.delete('visits', where: 'restaurantId = ?', whereArgs: [restaurantId]);
      await txn.delete('restaurants', where: 'id = ?', whereArgs: [restaurantId]);
    });
  }

  // --- VISIT CRUD ---

  Future<List<Visit>> getAllVisits() async {
    final db = await database;
    final maps = await db.query('visits', orderBy: 'visitDate DESC');
    return maps.map((map) => Visit.fromMap(map)).toList();
  }

  Future<List<Visit>> getVisitsForRestaurant(String restaurantId) async {
    final db = await database;
    final maps = await db.query(
      'visits',
      where: 'restaurantId = ?',
      whereArgs: [restaurantId],
      orderBy: 'visitDate DESC',
    );
    return maps.map((map) => Visit.fromMap(map)).toList();
  }

  Future<Visit?> getVisitById(String id) async {
    final db = await database;
    final maps = await db.query('visits', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Visit.fromMap(maps.first);
  }

  Future<void> insertVisit(Visit visit) async {
    final db = await database;
    await db.insert('visits', visit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateVisit(Visit visit) async {
    final db = await database;
    await db.update(
      'visits',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<void> deleteVisit(String visitId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('photos', where: 'visitId = ?', whereArgs: [visitId]);
      await txn.delete('visits', where: 'id = ?', whereArgs: [visitId]);
    });
  }

  // --- PHOTO CRUD ---

  Future<List<Photo>> getAllPhotos() async {
    final db = await database;
    final maps = await db.query('photos', orderBy: 'createdAt DESC');
    return maps.map((map) => Photo.fromMap(map)).toList();
  }

  Future<List<Photo>> getPhotosForRestaurant(String restaurantId) async {
    final db = await database;
    final maps = await db.query(
      'photos',
      where: 'restaurantId = ?',
      whereArgs: [restaurantId],
      orderBy: 'sortOrder ASC, createdAt DESC',
    );
    return maps.map((map) => Photo.fromMap(map)).toList();
  }

  Future<List<Photo>> getPhotosForVisit(String visitId) async {
    final db = await database;
    final maps = await db.query(
      'photos',
      where: 'visitId = ?',
      whereArgs: [visitId],
      orderBy: 'sortOrder ASC, createdAt ASC',
    );
    return maps.map((map) => Photo.fromMap(map)).toList();
  }

  Future<void> insertPhoto(Photo photo) async {
    final db = await database;
    await db.insert('photos', photo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePhoto(String photoId) async {
    final db = await database;
    await db.delete('photos', where: 'id = ?', whereArgs: [photoId]);
  }

  // --- CLEAR / RESET DATABASE ---

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('photos');
      await txn.delete('visits');
      await txn.delete('restaurants');
    });
  }
}
