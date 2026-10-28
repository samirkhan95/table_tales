import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/visit.dart';
import '../models/photo.dart';
import '../models/restaurant.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/date_formatter.dart';
import '../utils/haptic_service.dart';
import 'glass_container.dart';
import 'photo_lightbox.dart';
import 'rating_bar.dart';
import 'safe_image.dart';

class VisitCard extends StatelessWidget {
  final Visit visit;
  final Restaurant? restaurant;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showRestaurantHeader;

  const VisitCard({
    super.key,
    required this.visit,
    this.restaurant,
    this.onEdit,
    this.onDelete,
    this.showRestaurantHeader = false,
  });

  Widget _buildPhotoThumbnail(BuildContext context, Photo photo, List<Photo> allVisitPhotos, int index, {int remainingCount = 0}) {
    return GestureDetector(
      onTap: () {
        AppHaptics.lightImpact(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PhotoLightbox(photos: allVisitPhotos, initialIndex: index),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeImage(filePath: photo.filePath),
              if (remainingCount > 0)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '+$remainingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<RestaurantProvider>(context);

    final targetRestaurant = restaurant ??
        provider.allRestaurants.firstWhere(
          (r) => r.id == visit.restaurantId,
          orElse: () => Restaurant(name: 'Unknown Restaurant'),
        );

    final visitPhotos = provider.getPhotosForVisit(visit.id);
    final dateStr = DateFormatter.formatFull(visit.visitDate, isApproximate: visit.isApproximateDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: AppDesignTokens.borderRadiusLarge,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Header (for Timeline / Multi-restaurant views)
            if (showRestaurantHeader) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.champagneGold.withAlpha((0.2 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restaurant, size: 15, color: AppColors.champagneGold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      targetRestaurant.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontFamily: 'Serif',
                      ),
                    ),
                  ),
                  if (visit.rating != null) RatingBar(rating: visit.rating!, itemSize: 14),
                ],
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withAlpha((0.08 * 255).round())
                    : Colors.black.withAlpha((0.06 * 255).round()),
              ),
              const SizedBox(height: 10),
            ],

            // Date & Actions Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.champagneGold.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.champagneGold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Serif',
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (!showRestaurantHeader && visit.rating != null) ...[
                        const SizedBox(height: 2),
                        RatingBar(rating: visit.rating!, itemSize: 13),
                      ],
                    ],
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    onSelected: (val) {
                      AppHaptics.selectionClick(context);
                      if (val == 'edit') onEdit?.call();
                      if (val == 'delete') onDelete?.call();
                    },
                    itemBuilder: (ctx) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Visit'),
                          ]),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete Visit', style: TextStyle(color: AppColors.error)),
                          ]),
                        ),
                    ],
                  ),
              ],
            ),

            // Tags (Occasion & Meal Type)
            if (visit.mealType != null || visit.occasion != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (visit.occasion != null && visit.occasion!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.champagneGold.withAlpha((0.18 * 255).round()),
                        borderRadius: AppDesignTokens.borderRadiusPill,
                        border: Border.all(
                          color: AppColors.champagneGold.withAlpha((0.3 * 255).round()),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.celebration_outlined, size: 12, color: AppColors.champagneGold),
                          const SizedBox(width: 4),
                          Text(
                            visit.occasion!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.champagneGold),
                          ),
                        ],
                      ),
                    ),
                  if (visit.mealType != null && visit.mealType!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                        borderRadius: AppDesignTokens.borderRadiusPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant_outlined, size: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            visit.mealType!,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],

            // Memory Story / Notes
            if (visit.notes != null && visit.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                decoration: BoxDecoration(
                  border: const Border(
                    left: BorderSide(color: AppColors.champagneGold, width: 2.5),
                  ),
                  color: isDark
                      ? Colors.white.withAlpha((0.03 * 255).round())
                      : Colors.black.withAlpha((0.02 * 255).round()),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                ),
                child: Text(
                  visit.notes!,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],

            // Photos Strip
            if (visitPhotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visitPhotos.length > 5 ? 5 : visitPhotos.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final remaining = (idx == 4 && visitPhotos.length > 5) ? visitPhotos.length - 5 : 0;
                    return _buildPhotoThumbnail(ctx, visitPhotos[idx], visitPhotos, idx, remainingCount: remaining);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
