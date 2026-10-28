import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class PhotoPickResult {
  final List<String> savedPaths;
  final String? error;

  PhotoPickResult({required this.savedPaths, this.error});
}

class PhotoStorageService {
  final ImagePicker _picker = ImagePicker();

  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB limit
  static const List<String> allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.heif',
    '.bmp',
    '.gif',
  ];

  /// Returns the persistent directory path where photos are stored.
  static Future<String> getPhotosDirectoryPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDir.path, 'table_tales_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir.path;
  }

  /// Resolves a photo path to a File object, ensuring relative paths or app doc directory moves are handled correctly.
  static Future<File?> getPhotoFile(String filePath) async {
    if (kIsWeb ||
        filePath.startsWith('http://') ||
        filePath.startsWith('https://') ||
        filePath.startsWith('blob:')) {
      return null;
    }

    try {
      final directFile = File(filePath);
      if (await directFile.exists()) {
        return directFile;
      }

      // Check relative path in app documents directory
      final filename = p.basename(filePath);
      final appDir = await getApplicationDocumentsDirectory();
      final photoFile = File(p.join(appDir.path, 'table_tales_photos', filename));
      if (await photoFile.exists()) {
        return photoFile;
      }

      // Check temporary cache directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, filename));
      if (await tempFile.exists()) {
        return tempFile;
      }
    } catch (e) {
      debugPrint('Error resolving photo file: $e');
    }
    return null;
  }

  /// Pick multiple photos from device gallery/file picker
  Future<PhotoPickResult> pickPhotosFromGallery() async {
    try {
      List<XFile> pickedFiles = [];
      try {
        pickedFiles = await _picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } catch (e) {
        debugPrint('pickMultiImage failed, trying single pickImage: $e');
        final single = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (single != null) {
          pickedFiles = [single];
        }
      }

      if (pickedFiles.isEmpty) {
        return PhotoPickResult(savedPaths: []);
      }

      List<String> savedPaths = [];
      List<String> errorMessages = [];

      for (final xFile in pickedFiles) {
        final ext = p.extension(xFile.path).toLowerCase();
        if (ext.isNotEmpty && !allowedExtensions.contains(ext) && !kIsWeb) {
          errorMessages.add('Skipped ${p.basename(xFile.path)}: Unsupported format ($ext)');
          continue;
        }

        if (!kIsWeb && xFile.path.isNotEmpty) {
          final file = File(xFile.path);
          if (await file.exists()) {
            final length = await file.length();
            if (length > maxFileSizeBytes) {
              errorMessages.add('Skipped ${p.basename(xFile.path)}: Oversized (>25MB)');
              continue;
            }
          }
        }

        final savedPath = await saveImageToLocalStorage(xFile.path);
        if (savedPath != null) {
          savedPaths.add(savedPath);
        } else {
          errorMessages.add('Failed to save ${p.basename(xFile.path)}');
        }
      }

      return PhotoPickResult(
        savedPaths: savedPaths,
        error: errorMessages.isNotEmpty ? errorMessages.join('\n') : null,
      );
    } catch (e) {
      debugPrint('Error picking photos from gallery: $e');
      return PhotoPickResult(
        savedPaths: [],
        error: 'Failed to open image picker: $e',
      );
    }
  }

  /// Take a single photo using camera
  Future<PhotoPickResult> takePhotoWithCamera() async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (xFile == null) {
        return PhotoPickResult(savedPaths: []);
      }

      final savedPath = await saveImageToLocalStorage(xFile.path);
      if (savedPath != null) {
        return PhotoPickResult(savedPaths: [savedPath]);
      } else {
        return PhotoPickResult(savedPaths: [], error: 'Failed to save camera photo');
      }
    } catch (e) {
      debugPrint('Error taking photo with camera: $e');
      return PhotoPickResult(savedPaths: [], error: 'Camera error: $e');
    }
  }

  /// Copy an image from temporary path to app persistent storage
  Future<String?> saveImageToLocalStorage(String sourcePath) async {
    try {
      if (kIsWeb) {
        return sourcePath;
      }

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('Source image file does not exist: $sourcePath');
        return null;
      }

      final photosDirPath = await getPhotosDirectoryPath();

      var ext = p.extension(sourcePath).toLowerCase();
      if (ext.isEmpty || !allowedExtensions.contains(ext)) {
        ext = '.jpg';
      }

      final fileName = '${const Uuid().v4()}$ext';
      final targetPath = p.join(photosDirPath, fileName);

      final savedFile = await sourceFile.copy(targetPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving image to local storage: $e');
      return null;
    }
  }

  /// Delete photo file if it exists in persistent storage
  Future<bool> deletePhotoFile(String filePath) async {
    try {
      if (kIsWeb) return true;

      final file = await getPhotoFile(filePath);
      if (file != null && await file.exists()) {
        await file.delete();
        return true;
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting photo file: $e');
      return false;
    }
  }
}
