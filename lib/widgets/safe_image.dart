import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/photo_storage_service.dart';
import '../theme/app_colors.dart';

class SafeImage extends StatelessWidget {
  final String? filePath;
  final BoxFit fit;
  final Widget? placeholder;

  const SafeImage({
    super.key,
    required this.filePath,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  Widget _buildDefaultPlaceholder() {
    return placeholder ??
        Container(
          color: AppColors.champagneGold.withAlpha(30),
          child: const Center(
            child: Icon(
              Icons.restaurant_rounded,
              color: AppColors.champagneGold,
              size: 28,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final path = filePath;
    if (path == null || path.isEmpty) {
      return _buildDefaultPlaceholder();
    }

    if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _buildDefaultPlaceholder(),
      );
    }

    if (kIsWeb) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _buildDefaultPlaceholder(),
      );
    }

    final directFile = File(path);
    if (directFile.existsSync()) {
      return Image.file(
        directFile,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _buildDefaultPlaceholder(),
      );
    }

    return FutureBuilder<File?>(
      future: PhotoStorageService.getPhotoFile(path),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.file(
            snapshot.data!,
            fit: fit,
            errorBuilder: (ctx, err, stack) => _buildDefaultPlaceholder(),
          );
        }
        return _buildDefaultPlaceholder();
      },
    );
  }
}
