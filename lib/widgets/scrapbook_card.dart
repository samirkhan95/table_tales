import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/photo.dart';
import '../models/restaurant.dart';
import '../models/visit.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/haptic_service.dart';
import 'glass_container.dart';
import 'photo_lightbox.dart';
import 'rating_bar.dart';
import 'safe_image.dart';

class ScrapbookCard extends StatelessWidget {
  final Visit visit;
  final Restaurant? restaurant;
  final List<Photo> photos;
  final int visitSequence;
  final int totalVisits;
  final int index;
  final bool enableTilt;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenRestaurant;

  const ScrapbookCard({
    super.key,
    required this.visit,
    required this.restaurant,
    required this.photos,
    required this.visitSequence,
    required this.totalVisits,
    required this.index,
    this.enableTilt = true,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onOpenRestaurant,
  });

  /// Map occasion text to an appropriate romantic/dining emoji.
  static String? getOccasionEmoji(String? occasion) {
    if (occasion == null || occasion.trim().isEmpty) return null;
    final lower = occasion.toLowerCase();
    if (lower.contains('anniversary')) return '🥂';
    if (lower.contains('birthday')) return '🎂';
    if (lower.contains('date night') || lower.contains('romantic')) return '❤️';
    if (lower.contains('celebration')) return '🎉';
    if (lower.contains('vacation') || lower.contains('travel') || lower.contains('trip') || lower.contains('getaway')) {
      return '✈️';
    }
    if (lower.contains('brunch') || lower.contains('breakfast')) return '☕';
    if (lower.contains('lunch')) return '☀️';
    if (lower.contains('dinner')) return '🌙';
    if (lower.contains('drinks') || lower.contains('bar') || lower.contains('wine')) return '🍷';
    return '✨';
  }

  /// Calculates a gentle, organic album tilt angle (in radians).
  double _calculateTilt(BuildContext context) {
    if (!enableTilt) return 0.0;
    if (MediaQuery.of(context).disableAnimations) return 0.0;

    switch (index % 4) {
      case 0:
        return -0.012;
      case 1:
        return 0.010;
      case 2:
        return -0.006;
      case 3:
      default:
        return 0.008;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tilt = _calculateTilt(context);

    final restaurantName = restaurant?.name ?? 'Restaurant Memory';
    final visitDate = visit.visitDate;

    // Date calculations
    final bool hasDate = visitDate != null;
    final String dayStr = hasDate ? DateFormat('d').format(visitDate) : '—';
    final String monthYearStr = hasDate ? DateFormat('MMM yyyy').format(visitDate) : 'Undated';
    final String dayOfWeekStr = hasDate ? DateFormat('EEEE').format(visitDate) : 'Date not recorded';

    // Time or meal-type indicator
    String timeOrMealStr = '';
    if (hasDate && (visitDate.hour != 0 || visitDate.minute != 0)) {
      timeOrMealStr = DateFormat('hh:mm a').format(visitDate);
    } else if (visit.mealType != null && visit.mealType!.isNotEmpty) {
      timeOrMealStr = visit.mealType!;
    } else if (visit.isApproximateDate) {
      timeOrMealStr = 'Approx.';
    }

    final occasionEmoji = getOccasionEmoji(visit.occasion);

    final String sequenceText = visitSequence > 0
        ? (totalVisits > 1 ? 'Visit #$visitSequence' : '1st Visit')
        : '';

    final cardWidget = GlassContainer(
      borderRadius: AppDesignTokens.borderRadiusLarge,
      padding: const EdgeInsets.all(14),
      onTap: () {
        AppHaptics.lightImpact(context);
        onTap();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== LEFT DATE BADGE COLUMN ====================
          _buildDateBadgeColumn(
            context: context,
            isDark: isDark,
            dayStr: dayStr,
            monthYearStr: monthYearStr,
            timeOrMealStr: timeOrMealStr,
            hasDate: hasDate,
          ),

          const SizedBox(width: 12),

          // Subtle vertical champagne accent separator line
          Container(
            width: 1.5,
            height: photos.isNotEmpty ? 120 : 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.champagneGold.withAlpha((0.6 * 255).round()),
                  AppColors.champagneGold.withAlpha((0.15 * 255).round()),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          const SizedBox(width: 12),

          // ==================== RIGHT MAIN ALBUM CONTENT ====================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Day of Week & Visit Sequence Badge on Left, Occasion Pill & Menu on Right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        sequenceText.isNotEmpty
                            ? '$dayOfWeekStr • $sequenceText'
                            : dayOfWeekStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (visit.occasion != null && visit.occasion!.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.champagneGold.withAlpha((0.15 * 255).round()),
                            borderRadius: AppDesignTokens.borderRadiusPill,
                            border: Border.all(
                              color: AppColors.champagneGold.withAlpha((0.3 * 255).round()),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (occasionEmoji != null) ...[
                                Text(occasionEmoji, style: const TextStyle(fontSize: 10)),
                                const SizedBox(width: 3),
                              ],
                              Flexible(
                                child: Text(
                                  visit.occasion!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.champagneGold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    _buildCardMenu(context),
                  ],
                ),

                const SizedBox(height: 3),

                // Restaurant Name (Title)
                InkWell(
                  onTap: () {
                    if (onOpenRestaurant != null) {
                      AppHaptics.lightImpact(context);
                      onOpenRestaurant!();
                    } else {
                      onTap();
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Text(
                    restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),

                // Rating & Location subtitle if available
                if (visit.rating != null || (restaurant?.location != null && restaurant!.location!.isNotEmpty)) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (visit.rating != null) ...[
                        RatingBar(rating: visit.rating!, itemSize: 13),
                        const SizedBox(width: 6),
                      ],
                      if (restaurant?.location != null && restaurant!.location!.isNotEmpty)
                        Expanded(
                          child: Text(
                            restaurant!.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                // Visit Notes / Occasion Snippet
                if (visit.notes != null && visit.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    visit.notes!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],

                // ==================== PHOTO ALBUM THUMBNAIL ROW ====================
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildPhotoAlbumStrip(context, photos),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (tilt != 0.0) {
      return Transform.rotate(
        angle: tilt,
        alignment: Alignment.center,
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  /// Left date column styled as a champagne-tinted editorial badge.
  Widget _buildDateBadgeColumn({
    required BuildContext context,
    required bool isDark,
    required String dayStr,
    required String monthYearStr,
    required String timeOrMealStr,
    required bool hasDate,
  }) {
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.champagneGold.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.champagneGold.withAlpha((0.25 * 255).round()),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dayStr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.0,
                fontFamily: 'Serif',
                color: hasDate
                    ? AppColors.champagneGold
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              monthYearStr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          if (timeOrMealStr.isNotEmpty) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(6),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  timeOrMealStr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Photo album strip with rounded thumbnails and "+N" overlay.
  Widget _buildPhotoAlbumStrip(BuildContext context, List<Photo> photosList) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final maxThumb = ((availableWidth - 16) / 3).clamp(40.0, 68.0);
        final thumbSize = math.min(maxThumb, 68.0);

        final displayCount = math.min(photosList.length, 3);
        final remainingCount = photosList.length - 2;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(displayCount, (idx) {
            final photo = photosList[idx];
            final isLastTileWithMore = (idx == 2 && photosList.length > 3);

            return Padding(
              padding: EdgeInsets.only(right: idx < displayCount - 1 ? 8.0 : 0.0),
              child: GestureDetector(
                onTap: () {
                  AppHaptics.lightImpact(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PhotoLightbox(
                        photos: photosList,
                        initialIndex: idx,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        SafeImage(
                          filePath: photo.filePath,
                          fit: BoxFit.cover,
                        ),
                        if (isLastTileWithMore)
                          Container(
                            color: Colors.black.withAlpha((0.55 * 255).round()),
                            alignment: Alignment.center,
                            child: Text(
                              '+$remainingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Compact overflow menu on the card for direct edit/delete/detail actions.
  Widget _buildCardMenu(BuildContext context) {
    if (onEdit == null && onDelete == null && onOpenRestaurant == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 26,
      height: 26,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
        onSelected: (val) {
          if (val == 'view_memory') {
            onTap();
          } else if (val == 'view_restaurant' && onOpenRestaurant != null) {
            onOpenRestaurant!();
          } else if (val == 'edit' && onEdit != null) {
            onEdit!();
          } else if (val == 'delete' && onDelete != null) {
            onDelete!();
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(
            value: 'view_memory',
            child: Row(
              children: [
                Icon(Icons.auto_stories_outlined, size: 18, color: AppColors.champagneGold),
                SizedBox(width: 8),
                Text('Open Memory'),
              ],
            ),
          ),
          if (onOpenRestaurant != null)
            const PopupMenuItem(
              value: 'view_restaurant',
              child: Row(
                children: [
                  Icon(Icons.restaurant_outlined, size: 18, color: AppColors.warmOlive),
                  SizedBox(width: 8),
                  Text('View Restaurant'),
                ],
              ),
            ),
          if (onEdit != null)
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Edit Visit'),
                ],
              ),
            ),
          if (onDelete != null)
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Delete Visit', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
