import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/restaurant_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/haptic_service.dart';
import '../widgets/glass_container.dart';
import 'add_edit_restaurant_screen.dart';
import 'add_edit_visit_screen.dart';
import 'home_screen.dart';
import 'timeline_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _showAddActionSheet(BuildContext context) {
    AppHaptics.mediumImpact(context);
    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha((0.50 * 255).round()),
      isScrollControlled: true,
      builder: (ctx) {
        return GlassContainer(
          useBackdropBlur: true,
          blur: 16.0,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Add to TableTales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.champagneGold.withAlpha((0.2 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restaurant_rounded, color: AppColors.champagneGold),
                  ),
                  title: const Text('Add Restaurant', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Save a new place to your dining collection'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.lightImpact(context);
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddEditRestaurantScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warmOlive.withAlpha((0.2 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.warmOlive),
                  ),
                  title: const Text('Record a Visit', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Log a date night, meal memory, or rating'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.lightImpact(context);
                    Navigator.of(ctx).pop();
                    _showRecordVisitRestaurantSelector(context, provider);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRecordVisitRestaurantSelector(BuildContext context, RestaurantProvider provider) {
    final restaurants = provider.allRestaurants;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (restaurants.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
          title: const Text('No Restaurants Added Yet'),
          content: const Text('Please add a restaurant first before recording a visit memory.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.champagneGold,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddEditRestaurantScreen()),
                );
              },
              child: const Text('Add Restaurant'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha((0.50 * 255).round()),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = restaurants
                .where((r) => r.name.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return GlassContainer(
              useBackdropBlur: true,
              blur: 16.0,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Restaurant',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New Restaurant'),
                          onPressed: () {
                            AppHaptics.lightImpact(context);
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AddEditRestaurantScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search restaurants...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) {
                          final r = filtered[idx];
                          return ListTile(
                            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(r.cuisine ?? r.location ?? 'No cuisine specified'),
                            trailing: const Icon(Icons.add_circle_outline, color: AppColors.champagneGold),
                            onTap: () {
                              AppHaptics.lightImpact(context);
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddEditVisitScreen(restaurantId: r.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _currentIndex == index;
    final activeColor = AppColors.champagneGold;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Expanded(
      child: InkWell(
        onTap: () {
          AppHaptics.selectionClick(context);
          setState(() => _currentIndex = index);
        },
        borderRadius: AppDesignTokens.borderRadiusMedium,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlusButton(BuildContext context) {
    return Expanded(
      child: Center(
        heightFactor: 1.0,
        child: GestureDetector(
          onTap: () => _showAddActionSheet(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.champagneGold,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.champagneGold.withAlpha((0.4 * 255).round()),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screens = [
      HomeScreen(onOpenSettings: () => setState(() => _currentIndex = 4)),
      const TimelineScreen(),
      const SizedBox.shrink(), // Index 2 is the plus action
      const StatisticsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: screens,
      ),
      extendBody: false,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg : AppColors.lightBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            0,
            12,
            MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom
                : 8.0,
          ),
          child: _buildGlassNavBar(),
        ),
      ),
    );
  }

  Widget _buildGlassNavBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveRadius = AppDesignTokens.borderRadiusPill;

    final bgColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;

    final borderColor = isDark
        ? Colors.white.withAlpha((0.10 * 255).round())
        : Colors.black.withAlpha((0.08 * 255).round());

    final shadow = isDark
        ? AppDesignTokens.glassShadowDark
        : AppDesignTokens.glassShadowLight;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: effectiveRadius,
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: shadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
          _buildNavItem(1, Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Our Story'),
          _buildPlusButton(context),
          _buildNavItem(3, Icons.insights_outlined, Icons.insights_rounded, 'Insights'),
          _buildNavItem(4, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
        ],
      ),
    );
  }
}
