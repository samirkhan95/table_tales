import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/restaurant_provider.dart';
import '../providers/settings_provider.dart';
import '../models/restaurant.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/haptic_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/custom_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/flash_memory_card.dart';
import '../widgets/glass_container.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/search_overlay.dart';
import 'add_edit_restaurant_screen.dart';
import 'restaurant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenSettings;

  const HomeScreen({super.key, required this.onOpenSettings});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isGridView = false;

  void _showSortDialog(BuildContext context, RestaurantProvider provider) {
    AppHaptics.selectionClick(context);
    final currentSort = provider.filterOptions.sortBy;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
        title: const Text('Sort Collection By', style: TextStyle(fontFamily: 'Serif')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sortTile(ctx, provider, 'recent', 'Recently Visited', currentSort),
            _sortTile(ctx, provider, 'visits', 'Most Visited', currentSort),
            _sortTile(ctx, provider, 'favorites', 'Favorites First', currentSort),
            _sortTile(ctx, provider, 'name', 'Alphabetical (A-Z)', currentSort),
            _sortTile(ctx, provider, 'rating', 'Highest Rated', currentSort),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(BuildContext ctx, RestaurantProvider provider, String value, String label, String currentSort) {
    final isSelected = currentSort == value;
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? AppColors.champagneGold : null,
      ),
      onTap: () {
        AppHaptics.selectionClick(ctx);
        provider.updateFilter(provider.filterOptions.copyWith(sortBy: value));
        Navigator.of(ctx).pop();
      },
    );
  }

  /// Collects all unique available photos across visits and restaurants for Flash Memory
  List<FlashMemoryItem> _getFlashMemoryItems(RestaurantProvider provider) {
    final List<FlashMemoryItem> items = [];
    final Set<String> seenPaths = {};

    // 1. All photos associated with visits and restaurants
    for (var p in provider.allPhotos) {
      if (p.filePath.isNotEmpty && !seenPaths.contains(p.filePath)) {
        seenPaths.add(p.filePath);
        final r = provider.allRestaurants.firstWhere(
          (rest) => rest.id == p.restaurantId,
          orElse: () => Restaurant(name: 'Our Memory'),
        );
        items.add(FlashMemoryItem(
          photoPath: p.filePath,
          restaurantName: r.name,
        ));
      }
    }

    // 2. Cover photos of restaurants if not already included
    for (var r in provider.allRestaurants) {
      if (r.coverPhotoPath != null &&
          r.coverPhotoPath!.isNotEmpty &&
          !seenPaths.contains(r.coverPhotoPath!)) {
        seenPaths.add(r.coverPhotoPath!);
        items.add(FlashMemoryItem(
          photoPath: r.coverPhotoPath!,
          restaurantName: r.name,
        ));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<RestaurantProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final restaurants = provider.filteredRestaurants;
    final flashItems = _getFlashMemoryItems(provider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Home Header: Wordmark on Left, ONE Compact Search Icon on Right
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandLogo(size: 26),
                        const SizedBox(height: 2),
                        Text(
                          settings.coupleNames.isNotEmpty ? "${settings.coupleNames}'s Food Story" : 'Our Food Story',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    // ONE compact search icon button
                    GlassContainer(
                      borderRadius: AppDesignTokens.borderRadiusPill,
                      padding: EdgeInsets.zero,
                      child: IconButton(
                        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
                        padding: EdgeInsets.zero,
                        iconSize: 19,
                        icon: const Icon(Icons.search_rounded, color: AppColors.champagneGold),
                        tooltip: 'Search Places',
                        onPressed: () {
                          AppHaptics.selectionClick(context);
                          SearchOverlay.show(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Overview Stats Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlassContainer(
                  borderRadius: AppDesignTokens.borderRadiusLarge,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(context, '${provider.totalUniqueRestaurants}', 'Places'),
                      _buildDivider(isDark),
                      _buildStatItem(context, '${provider.totalRecordedVisits}', 'Visits'),
                      _buildDivider(isDark),
                      _buildStatItem(context, '${provider.totalPhotosCount}', 'Photos'),
                    ],
                  ),
                ),
              ),
            ),

            // Flash Memory Section (Interactive 3-second auto-sliding random photos)
            if (flashItems.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flash Memory',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                      ),
                      const SizedBox(height: 8),
                      FlashMemoryCard(items: flashItems),
                    ],
                  ),
                ),
              ),

            // Collection Filters Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      CustomChip(
                        label: 'Favorites',
                        icon: Icons.star_rounded,
                        isSelected: provider.filterOptions.onlyFavorites,
                        onTap: () {
                          AppHaptics.selectionClick(context);
                          provider.updateFilter(
                            provider.filterOptions.copyWith(onlyFavorites: !provider.filterOptions.onlyFavorites),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      CustomChip(
                        label: 'Has Photos',
                        icon: Icons.photo_library_outlined,
                        isSelected: provider.filterOptions.onlyHasPhotos,
                        onTap: () {
                          AppHaptics.selectionClick(context);
                          provider.updateFilter(
                            provider.filterOptions.copyWith(onlyHasPhotos: !provider.filterOptions.onlyHasPhotos),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      CustomChip(
                        label: 'Sort: ${provider.filterOptions.sortBy}',
                        icon: Icons.sort_rounded,
                        onTap: () => _showSortDialog(context, provider),
                      ),
                      if (provider.filterOptions.hasActiveFilters) ...[
                        const SizedBox(width: 8),
                        ActionChip(
                          label: const Text('Clear Filters'),
                          avatar: const Icon(Icons.close, size: 14),
                          onPressed: () {
                            AppHaptics.selectionClick(context);
                            provider.resetFilters();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Collection Header & Grid Toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Our Restaurant Collection (${restaurants.length})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
                      onPressed: () {
                        AppHaptics.selectionClick(context);
                        setState(() {
                          _isGridView = !_isGridView;
                        });
                      },
                      tooltip: _isGridView ? 'Switch to List' : 'Switch to Grid',
                    ),
                  ],
                ),
              ),
            ),

            // Restaurant Collection Content
            restaurants.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.restaurant_menu_rounded,
                      title: provider.allRestaurants.isEmpty ? 'Start Your Food Story' : 'No matching restaurants',
                      message: provider.allRestaurants.isEmpty
                          ? 'Tap the "+" button below to add your first restaurant or visit!'
                          : 'Try adjusting your filters.',
                      actionLabel: provider.allRestaurants.isEmpty ? 'Add First Restaurant' : null,
                      onAction: provider.allRestaurants.isEmpty
                          ? () {
                              AppHaptics.lightImpact(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AddEditRestaurantScreen()),
                              );
                            }
                          : null,
                    ),
                  )
                : _isGridView
                    ? SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final r = restaurants[index];
                              return RestaurantCard(
                                restaurant: r,
                                isGrid: true,
                                onTap: () {
                                  AppHaptics.lightImpact(context);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantDetailScreen(restaurantId: r.id),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: restaurants.length,
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final r = restaurants[index];
                              return RestaurantCard(
                                restaurant: r,
                                isGrid: false,
                                onTap: () {
                                  AppHaptics.lightImpact(context);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantDetailScreen(restaurantId: r.id),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: restaurants.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.champagneGold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 28,
      width: 1,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}
