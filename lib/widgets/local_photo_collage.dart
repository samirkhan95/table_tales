import 'package:flutter/material.dart';

import '../models/photo.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/haptic_service.dart';
import 'glass_container.dart';
import 'photo_lightbox.dart';
import 'safe_image.dart';

class LocalPhotoCollageCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Photo> photos;
  final List<Photo> allPhotosContext;

  const LocalPhotoCollageCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.photos,
    required this.allPhotosContext,
  });

  void _openPhoto(BuildContext context, Photo photo) {
    AppHaptics.lightImpact(context);
    final targetList = allPhotosContext.isNotEmpty ? allPhotosContext : photos;
    final idx = targetList.indexWhere((p) => p.id == photo.id);
    final initialIndex = idx >= 0 ? idx : 0;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoLightbox(
          photos: targetList,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: AppDesignTokens.borderRadiusLarge,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collage Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Serif',
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.champagneGold.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${photos.length} photos',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.champagneGold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Render artistic collage based on photo count
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _buildCollageLayout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCollageLayout(BuildContext context) {
    if (photos.length == 1) {
      return AspectRatio(
        aspectRatio: 1.8,
        child: GestureDetector(
          onTap: () => _openPhoto(context, photos[0]),
          child: SafeImage(filePath: photos[0].filePath, fit: BoxFit.cover),
        ),
      );
    }

    if (photos.length == 2) {
      // 2-Photo Split Collage
      return SizedBox(
        height: 190,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _openPhoto(context, photos[0]),
                child: SafeImage(filePath: photos[0].filePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => _openPhoto(context, photos[1]),
                child: SafeImage(filePath: photos[1].filePath, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      );
    }

    if (photos.length == 3) {
      // 3-Photo Hero & Stack Collage
      return SizedBox(
        height: 230,
        child: Row(
          children: [
            // Left Hero
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () => _openPhoto(context, photos[0]),
                child: SafeImage(filePath: photos[0].filePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 4),
            // Right Stacked
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openPhoto(context, photos[1]),
                      child: SizedBox(
                        width: double.infinity,
                        child: SafeImage(filePath: photos[1].filePath, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openPhoto(context, photos[2]),
                      child: SizedBox(
                        width: double.infinity,
                        child: SafeImage(filePath: photos[2].filePath, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4+ Photos: Top Wide Hero + 3 Thumbnails Strip
    return SizedBox(
      height: 250,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _openPhoto(context, photos[0]),
              child: SizedBox(
                width: double.infinity,
                child: SafeImage(filePath: photos[0].filePath, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openPhoto(context, photos[1]),
                    child: SafeImage(filePath: photos[1].filePath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openPhoto(context, photos[2]),
                    child: SafeImage(filePath: photos[2].filePath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openPhoto(context, photos[3]),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        SafeImage(filePath: photos[3].filePath, fit: BoxFit.cover),
                        if (photos.length > 4)
                          Container(
                            color: Colors.black54,
                            alignment: Alignment.center,
                            child: Text(
                              '+${photos.length - 3}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
