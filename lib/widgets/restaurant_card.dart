import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/restaurant.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'rating_bar.dart';
import 'safe_image.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  final bool isGrid;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<RestaurantProvider>(context);

    final visitCount = provider.getVisitCountForRestaurant(restaurant.id);
    final lastVisitDate = provider.getMostRecentVisitDate(restaurant.id);
    final avgRating = provider.getAverageRatingForRestaurant(restaurant.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: isGrid
            ? _buildGridContent(context, isDark, visitCount, lastVisitDate, avgRating, provider)
            : _buildListContent(context, isDark, visitCount, lastVisitDate, avgRating, provider),
      ),
    );
  }

  Widget _buildGridContent(BuildContext context, bool isDark, int visitCount, DateTime? lastVisitDate, double? avgRating, RestaurantProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.4,
              child: SafeImage(filePath: restaurant.coverPhotoPath),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  foregroundColor: restaurant.isFavorite ? AppColors.favoriteGold : Colors.white,
                ),
                icon: Icon(
                  restaurant.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 20,
                ),
                onPressed: () => provider.toggleFavorite(restaurant.id),
              ),
            ),
            if (restaurant.cuisine != null && restaurant.cuisine!.isNotEmpty)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xB3000000),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    restaurant.cuisine!,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontFamily: 'Serif',
                ),
              ),
              if (restaurant.location != null && restaurant.location!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  restaurant.location!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.champagneGold.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$visitCount ${visitCount == 1 ? 'visit' : 'visits'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.champagneGold,
                      ),
                    ),
                  ),
                  if (avgRating != null) RatingBar(rating: avgRating, itemSize: 12),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListContent(BuildContext context, bool isDark, int visitCount, DateTime? lastVisitDate, double? avgRating, RestaurantProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: SafeImage(filePath: restaurant.coverPhotoPath),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontFamily: 'Serif',
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        restaurant.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        color: restaurant.isFavorite ? AppColors.favoriteGold : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        size: 22,
                      ),
                      onPressed: () => provider.toggleFavorite(restaurant.id),
                    ),
                  ],
                ),
                if (restaurant.cuisine != null || restaurant.priceRange != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (restaurant.cuisine != null && restaurant.cuisine!.isNotEmpty)
                        Text(
                          restaurant.cuisine!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      if (restaurant.cuisine != null && restaurant.priceRange != null)
                        Text(' • ', style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                      if (restaurant.priceRange != null)
                        Text(
                          CurrencyFormatter.formatPriceRange(restaurant.priceRange),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warmOlive),
                        ),
                    ],
                  ),
                ],
                if (restaurant.location != null && restaurant.location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          restaurant.location!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.champagneGold.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$visitCount ${visitCount == 1 ? 'visit' : 'visits'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.champagneGold,
                        ),
                      ),
                    ),
                    if (lastVisitDate != null)
                      Text(
                        'Last visit: ${DateFormatter.formatShort(lastVisitDate)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
