import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/restaurant.dart';
import '../models/visit.dart';
import '../providers/restaurant_provider.dart';
import '../screens/add_edit_visit_screen.dart';
import '../screens/restaurant_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/haptic_service.dart';
import 'custom_chip.dart';
import 'glass_container.dart';
import 'photo_lightbox.dart';
import 'rating_bar.dart';
import 'safe_image.dart';
import 'scrapbook_card.dart';

class OurStoryMemorySheet extends StatelessWidget {
  final Visit visit;
  final Restaurant? restaurant;
  final int visitSequence;
  final int totalVisits;

  const OurStoryMemorySheet({
    super.key,
    required this.visit,
    required this.restaurant,
    required this.visitSequence,
    required this.totalVisits,
  });

  static Future<void> show(
    BuildContext context, {
    required Visit visit,
    required Restaurant? restaurant,
    required int visitSequence,
    required int totalVisits,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OurStoryMemorySheet(
        visit: visit,
        restaurant: restaurant,
        visitSequence: visitSequence,
        totalVisits: totalVisits,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, RestaurantProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Memory?'),
        content: const Text(
          'Are you sure you want to remove this visit memory from your story? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      AppHaptics.heavyImpact(context);
      await provider.deleteVisit(visit.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit memory removed from timeline')),
        );
      }
    }
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

    final photos = provider.getPhotosForVisit(visit.id);
    final occasionEmoji = ScrapbookCard.getOccasionEmoji(visit.occasion);

    final visitDate = visit.visitDate;
    final dateFull = DateFormatter.formatFull(visitDate, isApproximate: visit.isApproximateDate);

    String timeStr = '';
    if (visitDate != null && (visitDate.hour != 0 || visitDate.minute != 0)) {
      timeStr = DateFormat('hh:mm a').format(visitDate);
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return GlassContainer(
      useBackdropBlur: true,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      padding: EdgeInsets.zero,
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag bar & header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Occasion / Sequence Pill
                              Row(
                                children: [
                                  if (visit.occasion != null && visit.occasion!.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.champagneGold.withAlpha((0.2 * 255).round()),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (occasionEmoji != null) ...[
                                            Text(occasionEmoji, style: const TextStyle(fontSize: 12)),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            visit.occasion!,
                                            style: const TextStyle(
                                              color: AppColors.champagneGold,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (visitSequence > 0)
                                    Text(
                                      totalVisits > 1 ? 'Visit #$visitSequence of $totalVisits' : 'First Visit',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Restaurant Name
                              InkWell(
                                onTap: () {
                                  AppHaptics.lightImpact(context);
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantDetailScreen(restaurantId: targetRestaurant.id),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        targetRestaurant.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Serif',
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.champagneGold),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 20),

              // Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    // Date & Time Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.champagneGold.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.champagneGold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateFull,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                              ),
                              if (timeStr.isNotEmpty || (visit.mealType != null && visit.mealType!.isNotEmpty))
                                Text(
                                  [
                                    if (timeStr.isNotEmpty) timeStr,
                                    if (visit.mealType != null && visit.mealType!.isNotEmpty) visit.mealType!,
                                  ].join(' • '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (visit.rating != null)
                          RatingBar(rating: visit.rating!, itemSize: 18),
                      ],
                    ),

                    // Amount spent if recorded
                    if (visit.amountSpent != null && visit.amountSpent! > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warmOlive.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.warmOlive),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Spent: ${CurrencyFormatter.formatAmount(visit.amountSpent, currency: visit.currency)}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Notes (Album Diary Entry)
                    if (visit.notes != null && visit.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.champagneGold.withAlpha(isDark ? 35 : 25),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.format_quote_rounded, size: 18, color: AppColors.champagneGold),
                                SizedBox(width: 6),
                                Text(
                                  'Memory Notes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: AppColors.champagneGold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              visit.notes!.trim(),
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.5,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Tags
                    if (visit.tags.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: visit.tags.map((t) => CustomChip(label: '#$t')).toList(),
                      ),
                    ],

                    // Photos Gallery Section
                    if (photos.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Visit Photos (${photos.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Serif'),
                          ),
                          Text(
                            'Tap photo to enlarge',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: photos.length,
                        itemBuilder: (ctx, pIdx) {
                          final photo = photos[pIdx];
                          return GestureDetector(
                            onTap: () {
                              AppHaptics.lightImpact(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PhotoLightbox(photos: photos, initialIndex: pIdx),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SafeImage(filePath: photo.filePath, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons Row: View Restaurant, Edit, Delete
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.champagneGold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusMedium),
                            ),
                            icon: const Icon(Icons.restaurant_rounded, size: 18),
                            label: const Text('View Restaurant', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              AppHaptics.lightImpact(context);
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RestaurantDetailScreen(restaurantId: targetRestaurant.id),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit Visit Memory',
                          onPressed: () {
                            AppHaptics.selectionClick(context);
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddEditVisitScreen(
                                  restaurantId: targetRestaurant.id,
                                  visit: visit,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          tooltip: 'Delete Visit Memory',
                          onPressed: () => _confirmDelete(context, provider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
