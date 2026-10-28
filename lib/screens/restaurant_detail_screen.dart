import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/restaurant.dart';
import '../models/visit.dart';
import '../models/photo.dart';
import '../providers/restaurant_provider.dart';
import '../services/photo_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/haptic_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/photo_lightbox.dart';
import '../widgets/safe_image.dart';
import '../widgets/visit_card.dart';
import 'add_edit_restaurant_screen.dart';
import 'add_edit_visit_screen.dart';

class PhotoGroup {
  final String title;
  final String? subtitle;
  final DateTime? date;
  final String? visitId;
  final List<Photo> photos;

  PhotoGroup({
    required this.title,
    this.subtitle,
    this.date,
    this.visitId,
    required this.photos,
  });
}

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PhotoStorageService _photoStorage = PhotoStorageService();
  bool _isUploadingPhotos = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openMaps(String? mapsUrl, String name, String? location) async {
    Uri? uri;
    if (mapsUrl != null && mapsUrl.isNotEmpty) {
      uri = Uri.tryParse(mapsUrl);
    } else if (location != null && location.isNotEmpty) {
      final query = Uri.encodeComponent('$name $location');
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<PhotoGroup> _buildPhotoGroups(List<Visit> visits, List<Photo> allPhotos) {
    final List<PhotoGroup> groups = [];
    final Set<String> processedPhotoIds = {};

    // Group photos by Visit (newest visit date first)
    for (var v in visits) {
      final vPhotos = allPhotos.where((p) => p.visitId == v.id).toList();
      if (vPhotos.isNotEmpty) {
        for (var p in vPhotos) {
          processedPhotoIds.add(p.id);
        }
        final dateStr = DateFormatter.formatFull(v.visitDate, isApproximate: v.isApproximateDate);
        final details = [
          if (v.occasion != null && v.occasion!.isNotEmpty) v.occasion!,
          if (v.mealType != null && v.mealType!.isNotEmpty) v.mealType!,
          '${vPhotos.length} ${vPhotos.length == 1 ? 'photo' : 'photos'}',
        ].join(' • ');

        groups.add(PhotoGroup(
          title: dateStr,
          subtitle: details,
          date: v.visitDate,
          visitId: v.id,
          photos: vPhotos,
        ));
      }
    }

    // Handle photos not associated with a specific visit
    final generalPhotos = allPhotos.where((p) => !processedPhotoIds.contains(p.id)).toList();
    if (generalPhotos.isNotEmpty) {
      groups.add(PhotoGroup(
        title: 'General Restaurant Photos',
        subtitle: '${generalPhotos.length} ${generalPhotos.length == 1 ? 'photo' : 'photos'}',
        visitId: null,
        photos: generalPhotos,
      ));
    }

    return groups;
  }

  Future<void> _addPhotosDirectly(RestaurantProvider provider, List<Visit> visits) async {
    AppHaptics.selectionClick(context);
    String? targetVisitId;

    if (visits.isNotEmpty) {
      if (visits.length == 1) {
        targetVisitId = visits.first.id;
      } else {
        final selected = await showModalBottomSheet<String?>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return GlassContainer(
              useBackdropBlur: true,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              padding: const EdgeInsets.all(20),
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
                    const Text(
                      'Select Visit Date for Photos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                    ),
                    const SizedBox(height: 12),
                    ...visits.map((v) {
                      final dateStr = DateFormatter.formatFull(v.visitDate, isApproximate: v.isApproximateDate);
                      final sub = [if (v.occasion != null) v.occasion!, if (v.mealType != null) v.mealType!].join(' • ');
                      return ListTile(
                        leading: const Icon(Icons.calendar_today_rounded, color: AppColors.champagneGold),
                        title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: sub.isNotEmpty ? Text(sub) : null,
                        onTap: () => Navigator.of(ctx).pop(v.id),
                      );
                    }),
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined, color: AppColors.warmOlive),
                      title: const Text('General Restaurant Photos'),
                      subtitle: const Text('Not linked to a specific visit date'),
                      onTap: () => Navigator.of(ctx).pop(null),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        targetVisitId = selected;
      }
    }

    setState(() => _isUploadingPhotos = true);
    try {
      final result = await _photoStorage.pickPhotosFromGallery();
      if (!mounted) return;

      if (result.error != null && result.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!), backgroundColor: AppColors.error),
        );
      }

      if (result.savedPaths.isNotEmpty) {
        AppHaptics.heavyImpact(context);
        await provider.addPhotosToRestaurant(widget.restaurantId, result.savedPaths, visitId: targetVisitId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${result.savedPaths.length} photo(s)!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding photos: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhotos = false);
      }
    }
  }

  Future<void> _confirmDeletePhoto(BuildContext context, RestaurantProvider provider, Photo photo) async {
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
        title: const Text('Delete Photo?'),
        content: const Text('Remove this photo from persistent storage?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await provider.deletePhoto(photo.id);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Photo deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<RestaurantProvider>(context);

    final restaurant = provider.allRestaurants.firstWhere(
      (r) => r.id == widget.restaurantId,
      orElse: () => Restaurant(name: 'Restaurant'),
    );

    final visits = provider.getVisitsForRestaurant(restaurant.id);
    final photos = provider.getPhotosForRestaurant(restaurant.id);
    final visitCount = visits.length;
    final firstVisit = provider.getFirstVisitDate(restaurant.id);
    final lastVisit = provider.getMostRecentVisitDate(restaurant.id);

    final photoGroups = _buildPhotoGroups(visits, photos);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              scrolledUnderElevation: 2,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Color(0xCC000000), blurRadius: 8)],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeImage(filePath: restaurant.coverPhotoPath),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black87,
                            Colors.black38,
                            Colors.transparent,
                            Color(0xCC000000),
                          ],
                          stops: [0.0, 0.25, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    restaurant.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: restaurant.isFavorite ? AppColors.favoriteGold : Colors.white,
                  ),
                  onPressed: () {
                    AppHaptics.mediumImpact(context);
                    provider.toggleFavorite(restaurant.id);
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      AppHaptics.selectionClick(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AddEditRestaurantScreen(restaurant: restaurant)),
                      );
                    } else if (val == 'delete') {
                      final nav = Navigator.of(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
                          title: const Text('Delete Restaurant?'),
                          content: const Text('This will permanently delete this restaurant and all associated visit records and photos.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        await provider.deleteRestaurant(restaurant.id);
                        if (mounted) {
                          nav.pop();
                        }
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Restaurant')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Restaurant', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cuisine & Price
                    Row(
                      children: [
                        if (restaurant.cuisine != null && restaurant.cuisine!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.champagneGold.withAlpha((0.2 * 255).round()),
                              borderRadius: AppDesignTokens.borderRadiusPill,
                            ),
                            child: Text(
                              restaurant.cuisine!,
                              style: const TextStyle(color: AppColors.champagneGold, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        if (restaurant.priceRange != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            CurrencyFormatter.formatPriceRange(restaurant.priceRange),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warmOlive, fontSize: 15),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Address
                    if (restaurant.location != null && restaurant.location!.isNotEmpty) ...[
                      InkWell(
                        onTap: () => _openMaps(restaurant.mapsUrl, restaurant.name, restaurant.location),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 18, color: AppColors.champagneGold),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                restaurant.location!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.champagneGold,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Visit statistics summary row
                    Row(
                      children: [
                        Expanded(
                          child: GlassContainer(
                            borderRadius: AppDesignTokens.borderRadiusMedium,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Text(
                                  '$visitCount',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.champagneGold),
                                ),
                                const Text('Total Visits', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GlassContainer(
                            borderRadius: AppDesignTokens.borderRadiusMedium,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    firstVisit != null ? DateFormatter.formatShort(firstVisit) : '—',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Text('First Visit', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GlassContainer(
                            borderRadius: AppDesignTokens.borderRadiusMedium,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    lastVisit != null ? DateFormatter.formatShort(lastVisit) : '—',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Text('Last Visit', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Primary Action: Record Visit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.champagneGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusMedium),
                        ),
                        onPressed: () {
                          AppHaptics.lightImpact(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditVisitScreen(restaurantId: restaurant.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Record Another Visit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.champagneGold,
                      labelColor: AppColors.champagneGold,
                      onTap: (_) => AppHaptics.selectionClick(context),
                      tabs: [
                        Tab(text: 'Visits ($visitCount)'),
                        Tab(text: 'Photos (${photos.length})'),
                        const Tab(text: 'About & Notes'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // 1. Visits Tab
            visits.isEmpty
                ? const EmptyState(
                    icon: Icons.history_edu_rounded,
                    title: 'No visits recorded yet',
                    message: 'Tap "Record Another Visit" above to log your first memory here.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: visits.length,
                    itemBuilder: (ctx, idx) {
                      final v = visits[idx];
                      return VisitCard(
                        visit: v,
                        restaurant: restaurant,
                        onEdit: () {
                          AppHaptics.selectionClick(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditVisitScreen(restaurantId: restaurant.id, visit: v),
                            ),
                          );
                        },
                        onDelete: () async {
                          AppHaptics.mediumImpact(context);
                          await provider.deleteVisit(v.id);
                        },
                      );
                    },
                  ),

            // 2. Photos Tab (Grouped by Visit Date)
            photos.isEmpty
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Saved Photos (0)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.champagneGold,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusPill),
                              ),
                              onPressed: _isUploadingPhotos ? null : () => _addPhotosDirectly(provider, visits),
                              icon: _isUploadingPhotos
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.add_a_photo_outlined, size: 18),
                              label: const Text('Add Photos'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: EmptyState(
                          icon: Icons.photo_library_outlined,
                          title: 'No photos yet',
                          message: 'Tap "Add Photos" above to add memories to ${restaurant.name}!',
                          actionLabel: 'Add Photos',
                          onAction: () => _addPhotosDirectly(provider, visits),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Saved Photos (${photos.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.champagneGold,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusPill),
                              ),
                              onPressed: _isUploadingPhotos ? null : () => _addPhotosDirectly(provider, visits),
                              icon: _isUploadingPhotos
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.add_a_photo_outlined, size: 18),
                              label: const Text('Add Photos'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: photoGroups.length,
                          itemBuilder: (ctx, gIdx) {
                            final group = photoGroups[gIdx];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Group Header
                                Padding(
                                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.champagneGold.withAlpha((0.2 * 255).round()),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.champagneGold),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              group.title,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Serif',
                                              ),
                                            ),
                                            if (group.subtitle != null && group.subtitle!.isNotEmpty)
                                              Text(
                                                group.subtitle!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Group Photos Grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: group.photos.length,
                                  itemBuilder: (ctx, idx) {
                                    final p = group.photos[idx];
                                    return GestureDetector(
                                      onTap: () {
                                        AppHaptics.lightImpact(context);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PhotoLightbox(photos: group.photos, initialIndex: idx),
                                          ),
                                        );
                                      },
                                      onLongPress: () {
                                        AppHaptics.heavyImpact(context);
                                        _confirmDeletePhoto(context, provider, p);
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox.expand(
                                          child: SafeImage(filePath: p.filePath),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),

            // 3. About & Notes Tab
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (restaurant.description != null && restaurant.description!.isNotEmpty) ...[
                  const Text('Overall Notes & Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Serif')),
                  const SizedBox(height: 8),
                  Text(restaurant.description!, style: const TextStyle(fontSize: 14, height: 1.4)),
                  const SizedBox(height: 20),
                ],
                if (restaurant.tags.isNotEmpty) ...[
                  const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Serif')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: restaurant.tags.map((t) => Chip(label: Text('#$t'))).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                if (restaurant.website != null || restaurant.phone != null) ...[
                  const Text('Contact & Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Serif')),
                  const SizedBox(height: 8),
                  if (restaurant.website != null)
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(restaurant.website!),
                      onTap: () async {
                        AppHaptics.selectionClick(context);
                        final uri = Uri.tryParse(restaurant.website!);
                        if (uri != null && await canLaunchUrl(uri)) launchUrl(uri);
                      },
                    ),
                  if (restaurant.phone != null)
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(restaurant.phone!),
                      onTap: () async {
                        AppHaptics.selectionClick(context);
                        final uri = Uri.parse('tel:${restaurant.phone}');
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
