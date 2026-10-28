import 'package:flutter/material.dart';

import '../models/memory_collection.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/haptic_service.dart';
import 'glass_container.dart';
import 'safe_image.dart';

class MemoryCollectionCard extends StatelessWidget {
  final MemoryCollection collection;
  final VoidCallback onTap;

  const MemoryCollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
  });

  IconData _getIconForType(CollectionType type) {
    switch (type) {
      case CollectionType.favorites:
        return Icons.favorite_rounded;
      case CollectionType.year:
        return Icons.calendar_month_rounded;
      case CollectionType.occasion:
        return Icons.celebration_rounded;
      case CollectionType.recent:
        return Icons.access_time_rounded;
      case CollectionType.allAdventures:
        return Icons.auto_stories_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {

    return GlassContainer(
      borderRadius: AppDesignTokens.borderRadiusLarge,
      padding: EdgeInsets.zero,
      onTap: () {
        AppHaptics.lightImpact(context);
        onTap();
      },
      child: SizedBox(
        width: 170,
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Photo
            ClipRRect(
              borderRadius: AppDesignTokens.borderRadiusLarge,
              child: SafeImage(
                filePath: collection.coverPhotoPath,
                fit: BoxFit.cover,
              ),
            ),

            // Subtle dark gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                borderRadius: AppDesignTokens.borderRadiusLarge,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black26,
                    Colors.transparent,
                    Colors.black87,
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // Top Type Icon Badge
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Icon(
                  _getIconForType(collection.type),
                  color: AppColors.champagneGold,
                  size: 14,
                ),
              ),
            ),

            // Bottom Information
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    collection.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.champagneGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${collection.count}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          collection.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
