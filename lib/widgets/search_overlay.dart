import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/restaurant.dart';
import '../providers/restaurant_provider.dart';
import '../screens/restaurant_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/date_formatter.dart';
import '../utils/haptic_service.dart';
import 'glass_container.dart';
import 'safe_image.dart';

class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black45,
        transitionDuration: AppDesignTokens.animNormal,
        reverseTransitionDuration: AppDesignTokens.animFast,
        pageBuilder: (context, animation, secondaryAnimation) {
          return const SearchOverlay();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          final slide = Tween<Offset>(
            begin: const Offset(0.0, -0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Restaurant> _getSearchResults(RestaurantProvider provider) {
    if (_query.trim().isEmpty) return provider.allRestaurants;

    final q = _query.trim().toLowerCase();
    return provider.allRestaurants.where((r) {
      final nameMatch = r.name.toLowerCase().contains(q);
      final locMatch = r.location?.toLowerCase().contains(q) ?? false;
      final cuisMatch = r.cuisine?.toLowerCase().contains(q) ?? false;
      final tagsMatch = r.tags.any((t) => t.toLowerCase().contains(q));

      // Match visit notes
      final visits = provider.getVisitsForRestaurant(r.id);
      final notesMatch = visits.any((v) => v.notes?.toLowerCase().contains(q) ?? false);

      return nameMatch || locMatch || cuisMatch || tagsMatch || notesMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<RestaurantProvider>(context);
    final results = _getSearchResults(provider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBg.withAlpha((0.92 * 255).round())
          : AppColors.lightBg.withAlpha((0.92 * 255).round()),
      body: SafeArea(
        child: Column(
          children: [
            // Liquid Glass Search Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Close Search',
                      onPressed: () {
                        AppHaptics.selectionClick(context);
                        Navigator.of(context).pop();
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search places, cuisines, notes...',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          filled: false,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _query = val;
                          });
                        },
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        tooltip: 'Clear',
                        onPressed: () {
                          AppHaptics.selectionClick(context);
                          _controller.clear();
                          setState(() {
                            _query = '';
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Search Filter Summary
            if (_query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      'Found ${results.length} ${results.length == 1 ? 'place' : 'places'} for "${_query.trim()}"',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.champagneGold,
                      ),
                    ),
                  ],
                ),
              ),

            // Results List / Empty State
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No matching restaurants',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try searching for a different name, cuisine, location, or memory keyword.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: results.length,
                      itemBuilder: (ctx, idx) {
                        final r = results[idx];
                        final visitCount = provider.getVisitCountForRestaurant(r.id);
                        final lastVisit = provider.getMostRecentVisitDate(r.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassContainer(
                            borderRadius: AppDesignTokens.borderRadiusLarge,
                            onTap: () {
                              AppHaptics.lightImpact(context);
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RestaurantDetailScreen(restaurantId: r.id),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 54,
                                      height: 54,
                                      child: SafeImage(filePath: r.coverPhotoPath),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Serif',
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (r.cuisine != null && r.cuisine!.isNotEmpty)
                                              Text(
                                                r.cuisine!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.champagneGold,
                                                ),
                                              ),
                                            if (r.cuisine != null && r.location != null && r.location!.isNotEmpty)
                                              Text(
                                                ' • ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                                ),
                                              ),
                                            if (r.location != null && r.location!.isNotEmpty)
                                              Expanded(
                                                child: Text(
                                                  r.location!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '$visitCount ${visitCount == 1 ? 'visit' : 'visits'}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.warmOlive,
                                              ),
                                            ),
                                            if (lastVisit != null) ...[
                                              Text(
                                                ' • Last: ${DateFormatter.formatShort(lastVisit)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: AppColors.champagneGold,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
