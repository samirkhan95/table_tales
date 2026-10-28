import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_settings.dart';
import '../models/restaurant.dart';
import '../models/visit.dart';
import '../models/photo.dart';
import 'database_service.dart';
import 'photo_storage_service.dart';

class BackupPreview {
  final int restaurantsCount;
  final int visitsCount;
  final int photosCount;
  final int photoFilesCount;
  final DateTime? exportedAt;
  final String? version;
  final String? coupleNames;
  final bool isValid;
  final String? error;

  BackupPreview({
    required this.restaurantsCount,
    required this.visitsCount,
    required this.photosCount,
    required this.photoFilesCount,
    this.exportedAt,
    this.version,
    this.coupleNames,
    this.isValid = true,
    this.error,
  });
}

class ExportResult {
  final bool success;
  final bool canceled;
  final String? filePath;
  final String? tempPath;
  final int restaurantsCount;
  final int visitsCount;
  final int photosCount;
  final int photoFilesCount;
  final int fileSizeBytes;
  final String? errorMessage;

  ExportResult({
    required this.success,
    this.canceled = false,
    this.filePath,
    this.tempPath,
    this.restaurantsCount = 0,
    this.visitsCount = 0,
    this.photosCount = 0,
    this.photoFilesCount = 0,
    this.fileSizeBytes = 0,
    this.errorMessage,
  });
}

class BackupReport {
  final int restaurantsImported;
  final int visitsImported;
  final int photosImported;
  final int photoFilesRestored;
  final AppSettings? restoredSettings;
  final List<String> warnings;
  final List<String> errors;

  BackupReport({
    required this.restaurantsImported,
    required this.visitsImported,
    this.photosImported = 0,
    this.photoFilesRestored = 0,
    this.restoredSettings,
    required this.warnings,
    required this.errors,
  });

  bool get isSuccess =>
      errors.isEmpty &&
      (restaurantsImported > 0 || visitsImported > 0 || photosImported > 0);
}

class DataBackupService {
  final DatabaseService _dbService = DatabaseService();

  /// Export all data (Restaurants, Visits, Photos, embedded photo files, and App Settings) to JSON string
  Future<String> exportToJson({
    AppSettings? settings,
    void Function(int current, int total, String status)? onProgress,
  }) async {
    final restaurants = await _dbService.getAllRestaurants();
    final visits = await _dbService.getAllVisits();
    final photos = await _dbService.getAllPhotos();

    final Map<String, String> photoFiles = {};

    onProgress?.call(0, 100, 'Packaging places & visits...');
    await Future.delayed(Duration.zero);

    final totalPhotos = photos.length +
        restaurants.where((r) => r.coverPhotoPath != null && r.coverPhotoPath!.isNotEmpty).length;
    int photoIdx = 0;

    // 1. Collect and Base64-encode all visit / restaurant photo files
    for (final photo in photos) {
      if (photo.filePath.isNotEmpty) {
        final filename = p.basename(photo.filePath);
        if (!photoFiles.containsKey(filename)) {
          photoIdx++;
          onProgress?.call(photoIdx, totalPhotos, 'Encoding photo $photoIdx of $totalPhotos...');
          await Future.delayed(Duration.zero);

          final file = await PhotoStorageService.getPhotoFile(photo.filePath);
          if (file != null && await file.exists()) {
            try {
              final bytes = await file.readAsBytes();
              photoFiles[filename] = base64Encode(bytes);
            } catch (e) {
              debugPrint('Failed to read photo binary for ${photo.filePath}: $e');
            }
          }
        }
      }
    }

    // 2. Collect restaurant cover photos
    for (final rest in restaurants) {
      if (rest.coverPhotoPath != null && rest.coverPhotoPath!.isNotEmpty) {
        final filename = p.basename(rest.coverPhotoPath!);
        if (!photoFiles.containsKey(filename)) {
          photoIdx++;
          onProgress?.call(photoIdx, totalPhotos, 'Encoding photo $photoIdx of $totalPhotos...');
          await Future.delayed(Duration.zero);

          final file = await PhotoStorageService.getPhotoFile(rest.coverPhotoPath!);
          if (file != null && await file.exists()) {
            try {
              final bytes = await file.readAsBytes();
              photoFiles[filename] = base64Encode(bytes);
            } catch (e) {
              debugPrint('Failed to read cover photo binary for ${rest.coverPhotoPath}: $e');
            }
          }
        }
      }
    }

    onProgress?.call(totalPhotos, totalPhotos, 'Generating backup file...');
    await Future.delayed(Duration.zero);

    final exportMap = {
      'version': '2.0',
      'app': 'TableTales',
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': settings?.toJson(),
      'restaurants': restaurants.map((r) => r.toJson()).toList(),
      'visits': visits.map((v) => v.toJson()).toList(),
      'photos': photos.map((p) => p.toJson()).toList(),
      'photoFiles': photoFiles,
    };

    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  /// Exports backup to a .json file, opening the Android / OS file picker ("My Files" / Downloads)
  /// so the user can choose exactly where to save it.
  Future<ExportResult> exportBackupToFile({
    AppSettings? settings,
    void Function(int current, int total, String status)? onProgress,
  }) async {
    try {
      final restaurants = await _dbService.getAllRestaurants();
      final visits = await _dbService.getAllVisits();
      final photos = await _dbService.getAllPhotos();

      final jsonStr = await exportToJson(
        settings: settings,
        onProgress: onProgress,
      );
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultFileName = 'TableTales_Backup_$dateStr.json';

      // Always create a cache copy first so it's ready to share or fallback
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = p.join(tempDir.path, defaultFileName);
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(bytes, flush: false);

      int photoFilesCount = 0;
      try {
        final decoded = jsonDecode(jsonStr);
        photoFilesCount = (decoded['photoFiles'] as Map?)?.length ?? 0;
      } catch (_) {}

      onProgress?.call(100, 100, 'Opening save location...');
      await Future.delayed(Duration.zero);

      Uri? savedUri;
      try {
        savedUri = await FilePicker.saveFile(
          dialogTitle: 'Save TableTales Backup (My Files)',
          fileName: defaultFileName,
          bytes: bytes,
          mimeType: 'application/json',
        );
      } catch (pickerError) {
        debugPrint('FilePicker saveFile error: $pickerError');
      }

      if (savedUri != null) {
        String savedDisplayPath;
        if (savedUri.isScheme('file')) {
          savedDisplayPath = savedUri.toFilePath();
          final f = File(savedDisplayPath);
          if (!await f.exists() || (await f.length()) == 0) {
            await f.writeAsBytes(bytes, flush: false);
          }
        } else {
          savedDisplayPath = savedUri.toString();
        }

        return ExportResult(
          success: true,
          canceled: false,
          filePath: savedDisplayPath,
          tempPath: tempFilePath,
          restaurantsCount: restaurants.length,
          visitsCount: visits.length,
          photosCount: photos.length,
          photoFilesCount: photoFilesCount,
          fileSizeBytes: bytes.length,
        );
      } else {
        return ExportResult(
          success: false,
          canceled: true,
          tempPath: tempFilePath,
          restaurantsCount: restaurants.length,
          visitsCount: visits.length,
          photosCount: photos.length,
          photoFilesCount: photoFilesCount,
          fileSizeBytes: bytes.length,
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
      return ExportResult(
        success: false,
        canceled: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Share backup file via Android system sheet (Google Drive, WhatsApp, Email, etc.)
  Future<void> shareBackupFile(String filePath) async {
    final xFile = XFile(filePath, mimeType: 'application/json');
    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        subject: 'TableTales JSON Backup',
        text: 'My TableTales restaurant diary and memory backup.',
      ),
    );
  }

  /// Inspect and preview backup file contents before importing
  Future<BackupPreview> inspectBackup(String jsonContent) async {
    try {
      final dynamic decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        return BackupPreview(
          restaurantsCount: 0,
          visitsCount: 0,
          photosCount: 0,
          photoFilesCount: 0,
          isValid: false,
          error: 'Backup file is not a valid JSON object.',
        );
      }

      final restList = decoded['restaurants'] as List? ?? [];
      final visitList = decoded['visits'] as List? ?? [];
      final photoList = decoded['photos'] as List? ?? [];
      final photoFiles = (decoded['photoFiles'] ?? decoded['embeddedPhotos']) as Map? ?? {};

      DateTime? exportedAt;
      if (decoded['exportedAt'] != null) {
        exportedAt = DateTime.tryParse(decoded['exportedAt'].toString());
      }

      String? coupleNames;
      if (decoded['settings'] is Map && decoded['settings']['coupleNames'] != null) {
        coupleNames = decoded['settings']['coupleNames'].toString();
      }

      return BackupPreview(
        restaurantsCount: restList.length,
        visitsCount: visitList.length,
        photosCount: photoList.length,
        photoFilesCount: photoFiles.length,
        exportedAt: exportedAt,
        version: decoded['version']?.toString() ?? '1.0',
        coupleNames: coupleNames,
        isValid: true,
      );
    } catch (e) {
      return BackupPreview(
        restaurantsCount: 0,
        visitsCount: 0,
        photosCount: 0,
        photoFilesCount: 0,
        isValid: false,
        error: 'Invalid JSON format: $e',
      );
    }
  }

  /// Import/restore database and photo binaries from JSON backup string.
  /// If [clearExisting] is true, current database records are cleared first.
  Future<BackupReport> importFromJson(
    String jsonContent, {
    bool clearExisting = false,
    void Function(int current, int total, String status)? onProgress,
  }) async {
    int rCount = 0;
    int vCount = 0;
    int pCount = 0;
    int photoFilesRestored = 0;
    AppSettings? restoredSettings;
    List<String> warnings = [];
    List<String> errors = [];

    try {
      onProgress?.call(0, 100, 'Parsing backup file...');
      await Future.delayed(Duration.zero);

      final dynamic decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        errors.add('Backup file content is not a valid JSON structure.');
        return BackupReport(
          restaurantsImported: 0,
          visitsImported: 0,
          warnings: warnings,
          errors: errors,
        );
      }

      final Map<String, dynamic> data = decoded;
      final List<dynamic> restList = data['restaurants'] ?? [];
      final List<dynamic> visitList = data['visits'] ?? [];
      final List<dynamic> photoList = data['photos'] ?? [];
      final Map<String, dynamic> photoFiles =
          (data['photoFiles'] ?? data['embeddedPhotos']) is Map
              ? Map<String, dynamic>.from(data['photoFiles'] ?? data['embeddedPhotos'])
              : {};

      if (clearExisting) {
        onProgress?.call(0, 100, 'Preparing clean restore...');
        await Future.delayed(Duration.zero);
        await _dbService.clearAllData();
      }

      // 1. Restore photo binaries to local storage directory
      final photosDirPath = await PhotoStorageService.getPhotosDirectoryPath();
      final photosDir = Directory(photosDirPath);
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final totalPhotos = photoFiles.length;
      int photoIdx = 0;

      for (final entry in photoFiles.entries) {
        photoIdx++;
        onProgress?.call(photoIdx, totalPhotos, 'Restoring photo $photoIdx of $totalPhotos...');
        // Yield to allow UI animations and text to update
        await Future.delayed(Duration.zero);

        try {
          final filename = entry.key;
          final base64Content = entry.value.toString();
          if (base64Content.isNotEmpty) {
            final bytes = base64Decode(base64Content);
            final targetFile = File(p.join(photosDir.path, filename));
            await targetFile.writeAsBytes(bytes, flush: false);
            photoFilesRestored++;
          }
        } catch (e) {
          warnings.add('Failed to restore photo binary ${entry.key}: $e');
        }
      }

      // 2. Restore restaurants (re-linking cover photo paths to local storage)
      onProgress?.call(photoFilesRestored, totalPhotos, 'Restoring restaurants...');
      await Future.delayed(Duration.zero);

      for (var item in restList) {
        try {
          var r = Restaurant.fromJson(Map<String, dynamic>.from(item));
          if (r.coverPhotoPath != null && r.coverPhotoPath!.isNotEmpty) {
            final fname = p.basename(r.coverPhotoPath!);
            final localPhoto = File(p.join(photosDir.path, fname));
            if (await localPhoto.exists() || photoFiles.containsKey(fname)) {
              r = r.copyWith(coverPhotoPath: localPhoto.path);
            }
          }
          await _dbService.insertRestaurant(r);
          rCount++;
        } catch (e) {
          errors.add('Failed to import restaurant entry: $e');
        }
      }

      // 3. Restore visits
      onProgress?.call(photoFilesRestored, totalPhotos, 'Restoring visits & dates...');
      await Future.delayed(Duration.zero);

      for (var item in visitList) {
        try {
          final v = Visit.fromJson(Map<String, dynamic>.from(item));
          await _dbService.insertVisit(v);
          vCount++;
        } catch (e) {
          errors.add('Failed to import visit entry: $e');
        }
      }

      // 4. Restore photo metadata (re-linking file paths to local storage)
      for (var item in photoList) {
        try {
          var photo = Photo.fromJson(Map<String, dynamic>.from(item));
          if (photo.filePath.isNotEmpty) {
            final fname = p.basename(photo.filePath);
            final localPhoto = File(p.join(photosDir.path, fname));
            if (await localPhoto.exists() || photoFiles.containsKey(fname)) {
              photo = photo.copyWith(filePath: localPhoto.path);
            }
          }
          await _dbService.insertPhoto(photo);
          pCount++;
        } catch (e) {
          warnings.add('Failed to restore photo entry: $e');
        }
      }

      // 5. Restore settings if present
      if (data['settings'] is Map) {
        try {
          restoredSettings = AppSettings.fromJson(Map<String, dynamic>.from(data['settings']));
        } catch (e) {
          warnings.add('Could not restore app settings: $e');
        }
      }

      onProgress?.call(photoFilesRestored, totalPhotos, 'Finalizing...');
      await Future.delayed(Duration.zero);
    } catch (e) {
      errors.add('Invalid JSON format: $e');
    }

    return BackupReport(
      restaurantsImported: rCount,
      visitsImported: vCount,
      photosImported: pCount,
      photoFilesRestored: photoFilesRestored,
      restoredSettings: restoredSettings,
      warnings: warnings,
      errors: errors,
    );
  }
}
