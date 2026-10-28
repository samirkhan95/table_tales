import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/photo.dart';
import '../models/restaurant.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/photo_lightbox.dart';
import '../widgets/safe_image.dart';

class MemoriesGalleryScreen extends StatefulWidget {
  final String? initialRestaurantId;
  final int? initialYear;
  final String? initialOccasion;
  final bool initialFavoritesOnly;
  final String? initialTitle;

  const MemoriesGalleryScreen({
    super.key,
    this.initialRestaurantId,
    this.initialYear,
    this.initialOccasion,
    this.initialFavoritesOnly = false,
    this.initialTitle,
  });

  @override
  State<MemoriesGalleryScreen> createState() => _MemoriesGalleryScreenState();
}

class _MemoriesGalleryScreenState extends State<MemoriesGalleryScreen> {
  String? _selectedRestaurantId;
  int? _selectedYear;
  String? _selectedOccasion;
  bool _onlyFavorites = false;

  /// Disperses photos by restaurant so photos from the same place don't cluster side-by-side
  List<Photo> _dispersePhotosByRestaurant(List<Photo> photos, RestaurantProvider provider) {
    if (photos.length <= 2) return photos;

    // Group photos by restaurantId
    final Map<String, List<Photo>> grouped = {};
    for (final photo in photos) {
      grouped.putIfAbsent(photo.restaurantId, () => []).add(photo);
    }

    // Sort photos within each restaurant bucket by newest first
    for (var bucket in grouped.values) {
      bucket.sort((a, b) {
        final visitA = provider.getVisitById(a.visitId);
        final visitB = provider.getVisitById(b.visitId);
        final dateA = visitA?.visitDate ?? a.createdAt;
        final dateB = visitB?.visitDate ?? b.createdAt;
        return dateB.compareTo(dateA);
      });
    }

    // Sort buckets by size descending to interleave smoothly
    final buckets = grouped.values.map((list) => List<Photo>.from(list)).toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    // Interleave across buckets
    final List<Photo> result = [];
    int maxLen = buckets.first.length;
    for (int i = 0; i < maxLen; i++) {
      for (final bucket in buckets) {
        if (i < bucket.length) {
          result.add(bucket[i]);
        }
      }
    }
    return result;
  }

  /// Gentle organic hand-pinned tilt angles
  double _getTiltAngle(int index) {
    const angles = [
      -0.032, // -1.8 deg left
       0.026, // +1.5 deg right
      -0.018, // -1.0 deg left
       0.038, // +2.2 deg right
      -0.028, // -1.6 deg left
       0.012, // +0.7 deg right
      -0.036, // -2.0 deg left
       0.022, // +1.3 deg right
      -0.014, // -0.8 deg left
       0.030, // +1.7 deg right
    ];
    return angles[index % angles.length];
  }

  @override
  void initState() {
    super.initState();
    _selectedRestaurantId = widget.initialRestaurantId;
    _selectedYear = widget.initialYear;
    _selectedOccasion = widget.initialOccasion;
    _onlyFavorites = widget.initialFavoritesOnly;
  }

  void _clearFilters() {
    AppHaptics.selectionClick(context);
    setState(() {
      _selectedRestaurantId = null;
      _selectedYear = null;
      _selectedOccasion = null;
      _onlyFavorites = false;
    });
  }

  bool get _hasActiveFilters =>
      _selectedRestaurantId != null ||
      _selectedYear != null ||
      _selectedOccasion != null ||
      _onlyFavorites;

  /// Starts fullscreen gentle slideshow with current filtered photos
  void _startSlideshow(List<Photo> filteredPhotos) {
    if (filteredPhotos.isEmpty) return;
    AppHaptics.lightImpact(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoLightbox(
          photos: filteredPhotos,
          initialIndex: 0,
          isSlideshowActive: true,
          isShuffleMode: true,
          slideshowIntervalSeconds: 5,
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context, RestaurantProvider provider) {
    AppHaptics.selectionClick(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final restaurants = provider.allRestaurants;
    final recordedOccasions = provider.recordedOccasions;

    // Extract available years from visit dates
    final Set<int> availableYears = {};
    for (var v in provider.allVisits) {
      if (v.visitDate != null) {
        availableYears.add(v.visitDate!.year);
      }
    }
    final sortedYears = availableYears.toList()..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Gallery',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                        ),
                        if (_hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              _clearFilters();
                              setModalState(() {});
                              setState(() {});
                            },
                            child: const Text('Reset All'),
                          ),
                      ],
                    ),
                    const Divider(),

                    // 1. Restaurant Selector
                    const SizedBox(height: 8),
                    const Text('Restaurant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedRestaurantId,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Restaurants'),
                        ),
                        ...restaurants.map((r) => DropdownMenuItem<String?>(
                              value: r.id,
                              child: Text(r.name),
                            )),
                      ],
                      onChanged: (val) {
                        setModalState(() => _selectedRestaurantId = val);
                        setState(() => _selectedRestaurantId = val);
                      },
                    ),

                    // 2. Year Selector
                    if (sortedYears.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text('Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All Years'),
                            selected: _selectedYear == null,
                            onSelected: (selected) {
                              setModalState(() => _selectedYear = null);
                              setState(() => _selectedYear = null);
                            },
                          ),
                          ...sortedYears.map((yr) => ChoiceChip(
                                label: Text('$yr'),
                                selected: _selectedYear == yr,
                                onSelected: (selected) {
                                  final val = selected ? yr : null;
                                  setModalState(() => _selectedYear = val);
                                  setState(() => _selectedYear = val);
                                },
                              )),
                        ],
                      ),
                    ],

                    // 3. Occasion Selector (ONLY explicitly recorded occasions!)
                    if (recordedOccasions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text('Occasion (Stored Records Only)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ChoiceChip(
                            label: const Text('All Occasions'),
                            selected: _selectedOccasion == null,
                            onSelected: (selected) {
                              setModalState(() => _selectedOccasion = null);
                              setState(() => _selectedOccasion = null);
                            },
                          ),
                          ...recordedOccasions.map((occ) => ChoiceChip(
                                label: Text(occ),
                                selected: _selectedOccasion == occ,
                                onSelected: (selected) {
                                  final val = selected ? occ : null;
                                  setModalState(() => _selectedOccasion = val);
                                  setState(() => _selectedOccasion = val);
                                },
                              )),
                        ],
                      ),
                    ],

                    // 4. Favorites Toggle
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Favorites Only', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Show photos from your favorite places'),
                      value: _onlyFavorites,
                      activeThumbColor: AppColors.champagneGold,
                      onChanged: (val) {
                        setModalState(() => _onlyFavorites = val);
                        setState(() => _onlyFavorites = val);
                      },
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.champagneGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<RestaurantProvider>(context);

    // Apply combined filters strictly against real data
    List<Photo> filteredPhotos = provider.allPhotos.where((photo) {
      // 1. Restaurant filter
      if (_selectedRestaurantId != null && photo.restaurantId != _selectedRestaurantId) {
        return false;
      }

      // Look up associated visit & restaurant
      final visit = provider.getVisitById(photo.visitId);
      final restaurant = provider.getRestaurantById(photo.restaurantId);

      // 2. Favorites filter
      if (_onlyFavorites) {
        if (restaurant == null || !restaurant.isFavorite) {
          return false;
        }
      }

      // 3. Year filter
      if (_selectedYear != null) {
        final photoYear = visit?.visitDate?.year ?? photo.createdAt.year;
        if (photoYear != _selectedYear) {
          return false;
        }
      }

      // 4. Occasion filter (strictly matching stored data!)
      if (_selectedOccasion != null) {
        if (visit?.occasion == null || visit!.occasion!.trim().toLowerCase() != _selectedOccasion!.trim().toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();

    // Disperse photos so restaurants are spaced out across the gallery
    List<Photo> displayPhotos;
    if (_selectedRestaurantId == null) {
      displayPhotos = _dispersePhotosByRestaurant(filteredPhotos, provider);
    } else {
      displayPhotos = List<Photo>.from(filteredPhotos)
        ..sort((a, b) {
          final visitA = provider.getVisitById(a.visitId);
          final visitB = provider.getVisitById(b.visitId);
          final dateA = visitA?.visitDate ?? a.createdAt;
          final dateB = visitB?.visitDate ?? b.createdAt;
          return dateB.compareTo(dateA);
        });
    }

    final screenTitle = widget.initialTitle ?? 'Our Memories';
    final cozyBg = isDark ? const Color(0xFF191816) : const Color(0xFFF0EAE1);

    return Scaffold(
      backgroundColor: cozyBg,
      appBar: AppBar(
        backgroundColor: cozyBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              screenTitle,
              style: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${displayPhotos.length} ${displayPhotos.length == 1 ? "memory" : "memories"}',
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ],
        ),
        actions: [
          // Slideshow button
          IconButton(
            icon: const Icon(Icons.play_circle_outline_rounded),
            tooltip: 'Play Slideshow',
            onPressed: displayPhotos.isNotEmpty ? () => _startSlideshow(displayPhotos) : null,
          ),

          // Filter Button (with badge if active)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                tooltip: 'Filter Gallery',
                onPressed: () => _showFilterModal(context, provider),
              ),
              if (_hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.champagneGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters chip bar
          if (_hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF22201D) : const Color(0xFFE8E1D5).withValues(alpha: 0.6),
              child: Row(
                children: [
                  const Text('Active: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedRestaurantId != null) ...[
                            Chip(
                              label: Text(provider.getRestaurantById(_selectedRestaurantId)?.name ?? 'Restaurant'),
                              onDeleted: () => setState(() => _selectedRestaurantId = null),
                              deleteIconColor: AppColors.champagneGold,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_selectedYear != null) ...[
                            Chip(
                              label: Text('Year $_selectedYear'),
                              onDeleted: () => setState(() => _selectedYear = null),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_selectedOccasion != null) ...[
                            Chip(
                              label: Text(_selectedOccasion!),
                              onDeleted: () => setState(() => _selectedOccasion = null),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_onlyFavorites) ...[
                            Chip(
                              label: const Text('Favorites'),
                              onDeleted: () => setState(() => _onlyFavorites = false),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 6),
                          ],
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main Gallery Content
          Expanded(
            child: filteredPhotos.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: Icons.photo_library_outlined,
                      title: _hasActiveFilters ? 'No Matching Memories' : 'Our Story Awaits',
                      message: _hasActiveFilters
                          ? 'No photos match your current filter selection.'
                          : 'Our story is waiting to be filled with memories. Add photos when logging restaurant visits!',
                      actionLabel: _hasActiveFilters ? 'Clear Filters' : null,
                      onAction: _hasActiveFilters ? _clearFilters : null,
                    ),
                  )
                : _buildPolaroidMemoryWall(displayPhotos, provider, isDark),
          ),
        ],
      ),
    );
  }

  /// Responsive Polaroid memory wall
  Widget _buildPolaroidMemoryWall(List<Photo> photos, RestaurantProvider provider, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 2;
        if (width > 600) {
          crossAxisCount = 3;
        }
        if (width > 900) {
          crossAxisCount = 4;
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 80),
          clipBehavior: Clip.none,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
            childAspectRatio: 0.76,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            final restaurant = provider.getRestaurantById(photo.restaurantId);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: _buildPolaroidCard(
                context: context,
                photo: photo,
                restaurant: restaurant,
                index: index,
                isDark: isDark,
                onTap: () {
                  AppHaptics.lightImpact(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PhotoLightbox(
                        photos: photos,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Authentic vintage camera Polaroid card with handwritten restaurant name & golden pin
  Widget _buildPolaroidCard({
    required BuildContext context,
    required Photo photo,
    required Restaurant? restaurant,
    required int index,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final tiltAngle = _getTiltAngle(index);
    final restaurantName = restaurant?.name ?? 'Our Table';

    return Transform.rotate(
      angle: tiltAngle,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Polaroid Photographic Paper Frame
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDFBF7), // Warm vintage photo paper
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFFECE7DE),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo Area
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SafeImage(
                        filePath: photo.filePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Bottom White Chin with Handwritten Restaurant Name
                  Container(
                    height: 38,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.patrickHand(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C2824), // Vintage dark ink
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Golden Thumbtack / Pin on Top Edge
            Positioned(
              top: -6,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.35, -0.35),
                    radius: 0.75,
                    colors: [
                      Color(0xFFFFEE99), // Specular light reflection
                      Color(0xFFE5B83B), // Metallic gold body
                      Color(0xFF9E7B18), // Dark gold rim
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
