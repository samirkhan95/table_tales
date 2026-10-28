import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/restaurant_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/haptic_service.dart';
import '../widgets/glass_container.dart';
import 'memories_gallery_screen.dart';
import 'restaurant_detail_screen.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  void _openGallery(BuildContext context) {
    AppHaptics.lightImpact(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MemoriesGalleryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<RestaurantProvider>(context);

    final topVisited = provider.topVisitedRestaurants;
    final allPhotos = provider.allPhotos;

    // Calculate visits that have photos attached
    final visitsWithPhotosCount = provider.allVisits
        .where((v) => provider.getPhotosForVisit(v.id).isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Memories', style: TextStyle(fontFamily: 'Serif')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // ==================== SECTION 1: OUR MEMORIES HERO AREA ====================
          GlassContainer(
            borderRadius: AppDesignTokens.borderRadiusLarge,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'Our Memories',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Serif',
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.auto_stories_rounded, color: AppColors.champagneGold, size: 18),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Every table has a story. Every photo brings it back.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Compact summary badge showing actual stored numbers only
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.champagneGold.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 13, color: AppColors.champagneGold),
                          const SizedBox(width: 5),
                          Text(
                            '${allPhotos.length} ${allPhotos.length == 1 ? "Photo" : "Photos"}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.champagneGold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warmOlive.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.warmOlive),
                          const SizedBox(width: 5),
                          Text(
                            '$visitsWithPhotosCount Visits with photos',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warmOlive),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Button: Explore Gallery
                if (allPhotos.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.champagneGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusMedium),
                      ),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text(
                        'Explore Gallery',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () => _openGallery(context),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                      borderRadius: AppDesignTokens.borderRadiusMedium,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.champagneGold, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Our story is waiting to be filled with memories. Add photos when logging visits!',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==================== SECTION 2: DINING OVERVIEW ====================
          const Text(
            'Dining Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _metricTile(context, isDark, '${provider.totalUniqueRestaurants}', 'Unique Restaurants', Icons.restaurant),
              _metricTile(context, isDark, '${provider.totalRecordedVisits}', 'Total Visits Logged', Icons.confirmation_number_outlined),
              _metricTile(context, isDark, provider.avgVisitsPerRestaurant.toStringAsFixed(1), 'Avg Visits / Place', Icons.analytics_outlined),
              _metricTile(context, isDark, '${provider.totalPhotosCount}', 'Photos Preserved', Icons.photo_library_outlined),
            ],
          ),
          const SizedBox(height: 20),

          // ==================== SECTION 3: TOP VISITED RESTAURANTS (1st, 2nd, 3rd) ====================
          if (topVisited.isNotEmpty) ...[
            const Text(
              'Top Visited Restaurants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
            ),
            const SizedBox(height: 10),
            ...List.generate(topVisited.length, (index) {
              final r = topVisited[index];
              final visitCount = provider.getVisitCountForRestaurant(r.id);

              Color badgeColor;
              IconData badgeIcon;

              if (index == 0) {
                badgeColor = AppColors.champagneGold;
                badgeIcon = Icons.emoji_events_rounded;
              } else if (index == 1) {
                badgeColor = isDark ? const Color(0xFFC0C0C0) : const Color(0xFF7A8B8B);
                badgeIcon = Icons.workspace_premium_rounded;
              } else {
                badgeColor = AppColors.terracotta;
                badgeIcon = Icons.workspace_premium_rounded;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  borderRadius: AppDesignTokens.borderRadiusLarge,
                  onTap: () {
                    AppHaptics.lightImpact(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RestaurantDetailScreen(restaurantId: r.id),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: badgeColor,
                      child: Icon(badgeIcon, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      r.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                    ),
                    subtitle: Text('$visitCount ${visitCount == 1 ? "visit" : "visits"} recorded'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.champagneGold),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _metricTile(BuildContext context, bool isDark, String value, String label, IconData icon) {
    return GlassContainer(
      borderRadius: AppDesignTokens.borderRadiusLarge,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.champagneGold, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }
}
