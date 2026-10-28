import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/restaurant.dart';
import '../models/visit.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';
import '../utils/haptic_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/our_story_memory_sheet.dart';
import '../widgets/scrapbook_card.dart';
import 'add_edit_restaurant_screen.dart';
import 'add_edit_visit_screen.dart';
import 'restaurant_detail_screen.dart';

class TimelineScreen extends StatefulWidget {
  final bool showBackButton;

  const TimelineScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  // Feature 2: Oldest first by default so the timeline reads like a journey through time
  bool _isOldestFirst = true;
  String? _selectedYear; // null means 'All'
  String _searchQuery = '';
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Calculates a visit's chronological sequence number (e.g. 1st visit, 2nd visit)
  /// reliably from actual visit records for that restaurant.
  int _getVisitSequence(Visit visit, List<Visit> allVisits) {
    final rVisits = allVisits.where((v) => v.restaurantId == visit.restaurantId).toList();
    rVisits.sort((a, b) {
      if (a.visitDate == null && b.visitDate == null) return a.createdAt.compareTo(b.createdAt);
      if (a.visitDate == null) return 1;
      if (b.visitDate == null) return -1;
      final cmp = a.visitDate!.compareTo(b.visitDate!);
      if (cmp != 0) return cmp;
      return a.createdAt.compareTo(b.createdAt);
    });
    final idx = rVisits.indexWhere((v) => v.id == visit.id);
    return idx >= 0 ? idx + 1 : 1;
  }

  void _showRecordVisitPicker(BuildContext context, RestaurantProvider provider) {
    AppHaptics.lightImpact(context);
    final restaurants = provider.allRestaurants;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (restaurants.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddEditRestaurantScreen()),
      );
      return;
    }

    if (restaurants.length == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddEditVisitScreen(restaurantId: restaurants.first.id)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Record Memory For Which Place?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: restaurants.length,
                itemBuilder: (c, idx) {
                  final r = restaurants[idx];
                  return ListTile(
                    leading: const Icon(Icons.restaurant, color: AppColors.champagneGold),
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(r.cuisine ?? r.location ?? 'Place memory'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AddEditVisitScreen(restaurantId: r.id)),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<RestaurantProvider>(context);

    final allVisits = provider.allVisits;
    final allRestaurants = provider.allRestaurants;
    final canPopScreen = widget.showBackButton || Navigator.of(context).canPop();

    // Feature 6: Empty state when no restaurants exist
    if (allRestaurants.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context, isDark, 0, canPop: canPopScreen),
        body: Center(
          child: EmptyState(
            icon: Icons.auto_stories_outlined,
            title: 'Our Story Begins Here',
            message: 'Every great love story has its favorite tables. Add your first restaurant to start building your romantic scrapbook.',
            actionLabel: 'Add First Restaurant',
            onAction: () {
              AppHaptics.lightImpact(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditRestaurantScreen()),
              );
            },
          ),
        ),
      );
    }

    // Feature 6: Empty state when restaurants exist but no visits have been recorded
    if (allVisits.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context, isDark, 0, canPop: canPopScreen),
        body: Center(
          child: EmptyState(
            icon: Icons.history_edu_rounded,
            title: 'No Visits Recorded Yet',
            message: 'You have ${allRestaurants.length} saved places! Record your first meal or date night to see your scrapbook album come alive.',
            actionLabel: 'Record First Visit Memory',
            onAction: () => _showRecordVisitPicker(context, provider),
          ),
        ),
      );
    }

    // Extract available years for the year bar
    final availableYears = <String>{};
    bool hasUndated = false;
    for (var v in allVisits) {
      if (v.visitDate != null) {
        availableYears.add(v.visitDate!.year.toString());
      } else {
        hasUndated = true;
      }
    }
    final sortedYears = availableYears.toList()
      ..sort((a, b) => _isOldestFirst ? a.compareTo(b) : b.compareTo(a));

    // Separate dated and undated visits
    final datedVisits = allVisits.where((v) => v.visitDate != null).toList();
    final undatedVisits = allVisits.where((v) => v.visitDate == null).toList();

    // Sort dated visits chronologically based on _isOldestFirst
    datedVisits.sort((a, b) {
      final cmp = _isOldestFirst
          ? a.visitDate!.compareTo(b.visitDate!)
          : b.visitDate!.compareTo(a.visitDate!);
      if (cmp != 0) return cmp;
      return _isOldestFirst
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt);
    });

    // Sort undated visits by createdAt
    undatedVisits.sort((a, b) {
      return _isOldestFirst
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt);
    });

    // Combine according to sort direction:
    // Oldest-first: dated visits first, undated section at the end.
    // Newest-first: dated visits first, undated section at the end.
    List<Visit> sortedVisits = [...datedVisits, ...undatedVisits];

    // Filter by year if a year is selected
    if (_selectedYear != null) {
      if (_selectedYear == 'Undated') {
        sortedVisits = sortedVisits.where((v) => v.visitDate == null).toList();
      } else {
        sortedVisits = sortedVisits.where((v) => v.visitDate?.year.toString() == _selectedYear).toList();
      }
    }

    // Filter by search query if active
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      sortedVisits = sortedVisits.where((v) {
        final r = allRestaurants.firstWhere(
          (r) => r.id == v.restaurantId,
          orElse: () => Restaurant(name: ''),
        );
        final nameMatch = r.name.toLowerCase().contains(query);
        final notesMatch = v.notes?.toLowerCase().contains(query) ?? false;
        final occasionMatch = v.occasion?.toLowerCase().contains(query) ?? false;
        final tagsMatch = v.tags.any((t) => t.toLowerCase().contains(query));
        final mealMatch = v.mealType?.toLowerCase().contains(query) ?? false;
        return nameMatch || notesMatch || occasionMatch || tagsMatch || mealMatch;
      }).toList();
    }

    // Group visits by Month & Year, or "Date not recorded" for undated
    final Map<String, List<Visit>> grouped = {};
    for (var v in sortedVisits) {
      final String headerKey;
      if (v.visitDate != null) {
        headerKey = DateFormatter.formatMonthYear(v.visitDate);
      } else {
        headerKey = 'Date not recorded';
      }
      grouped.putIfAbsent(headerKey, () => []).add(v);
    }

    return Scaffold(
      appBar: _buildAppBar(context, isDark, sortedVisits.length, canPop: canPopScreen),
      body: Column(
        children: [
          // Search input bar when toggled
          if (_isSearchVisible)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search memories by place, note, occasion...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.champagneGold),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  isDense: true,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),

          // Horizontal Year Selector Bar (Feature 6: Compact Year selector)
          if (sortedYears.length > 1 || hasUndated)
            _buildYearSelectorBar(context, isDark, sortedYears, hasUndated),

          // Timeline Body
          Expanded(
            child: sortedVisits.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No Matching Memories',
                      message: _searchQuery.isNotEmpty
                          ? 'No scrapbook entries found matching "$_searchQuery".'
                          : 'No memories recorded for the selected period.',
                      actionLabel: 'Show All Memories',
                      onAction: () {
                        setState(() {
                          _selectedYear = null;
                          _searchQuery = '';
                          _searchController.clear();
                          _isSearchVisible = false;
                        });
                      },
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, groupIndex) {
                      final headerText = grouped.keys.elementAt(groupIndex);
                      final groupVisits = grouped[headerText]!;
                      final isUndatedSection = headerText == 'Date not recorded';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header with elegant champagne pill & divider
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isUndatedSection
                                        ? (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle)
                                        : AppColors.champagneGold,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isUndatedSection
                                        ? Border.all(
                                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isUndatedSection ? Icons.help_outline_rounded : Icons.calendar_month_rounded,
                                        size: 13,
                                        color: isUndatedSection
                                            ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        headerText,
                                        style: TextStyle(
                                          color: isUndatedSection
                                              ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Divider(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Album Cards in this section
                          ...groupVisits.asMap().entries.map((entry) {
                            final cardIdx = entry.key;
                            final visit = entry.value;

                            final restaurant = allRestaurants.firstWhere(
                              (r) => r.id == visit.restaurantId,
                              orElse: () => Restaurant(name: 'Restaurant Memory'),
                            );

                            final photos = provider.getPhotosForVisit(visit.id);
                            final seqNum = _getVisitSequence(visit, allVisits);
                            final totalCount = provider.getVisitCountForRestaurant(visit.restaurantId);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ScrapbookCard(
                                visit: visit,
                                restaurant: restaurant,
                                photos: photos,
                                visitSequence: seqNum,
                                totalVisits: totalCount,
                                index: groupIndex * 10 + cardIdx,
                                enableTilt: false,
                                onTap: () {
                                  OurStoryMemorySheet.show(
                                    context,
                                    visit: visit,
                                    restaurant: restaurant,
                                    visitSequence: seqNum,
                                    totalVisits: totalCount,
                                  );
                                },
                                onOpenRestaurant: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantDetailScreen(restaurantId: restaurant.id),
                                    ),
                                  );
                                },
                                onEdit: () {
                                  AppHaptics.selectionClick(context);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AddEditVisitScreen(
                                        restaurantId: restaurant.id,
                                        visit: visit,
                                      ),
                                    ),
                                  );
                                },
                                onDelete: () async {
                                  AppHaptics.mediumImpact(context);
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Memory?'),
                                      content: const Text('Are you sure you want to remove this visit from your story?'),
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
                                    await provider.deleteVisit(visit.id);
                                  }
                                },
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark, int totalCount, {bool canPop = false}) {
    return AppBar(
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
              onPressed: () {
                AppHaptics.lightImpact(context);
                Navigator.of(context).pop();
              },
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Our Story',
                style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 19),
              ),
              const SizedBox(width: 6),
              // Subtle heart icon consistent with romantic couple scrapbook identity
              const Icon(Icons.favorite_rounded, color: AppColors.softRose, size: 16),
            ],
          ),
          Text(
            'Every place, a story. Every visit, a memory.',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
      actions: [
        // Search toggle icon
        IconButton(
          icon: Icon(_isSearchVisible ? Icons.search_off_rounded : Icons.search_rounded),
          tooltip: _isSearchVisible ? 'Close Search' : 'Search Memories',
          onPressed: () {
            AppHaptics.selectionClick(context);
            setState(() {
              _isSearchVisible = !_isSearchVisible;
              if (!_isSearchVisible) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
        ),

        // Sort toggle: Oldest First <-> Newest First
        IconButton(
          icon: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: _isOldestFirst ? 1.0 : -1.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            builder: (context, scaleY, child) {
              return Transform(
                transform: Matrix4.diagonal3Values(1.0, scaleY, 1.0),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: const Icon(Icons.sort_rounded),
          ),
          tooltip: _isOldestFirst
              ? 'Journey Order: Oldest First (Tap for Newest First)'
              : 'Latest Memories: Newest First (Tap for Oldest First)',
          onPressed: () {
            AppHaptics.selectionClick(context);
            setState(() {
              _isOldestFirst = !_isOldestFirst;
            });
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 1400),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.champagneGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: Text(
                  _isOldestFirst
                      ? 'Sorting by Journey Order (Oldest First)'
                      : 'Sorting by Latest Memories (Newest First)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Horizontal scrolling year filter bar.
  Widget _buildYearSelectorBar(BuildContext context, bool isDark, List<String> years, bool hasUndated) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withAlpha(120)
            : AppColors.lightSurface.withAlpha(120),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder.withAlpha(100) : AppColors.lightBorder.withAlpha(100),
            width: 0.8,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 'All' filter chip
          _buildYearChip(
            label: 'All Memories',
            isSelected: _selectedYear == null,
            onTap: () {
              AppHaptics.selectionClick(context);
              setState(() => _selectedYear = null);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          // Each year chip
          ...years.map((year) {
            final isSelected = _selectedYear == year;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildYearChip(
                label: year,
                isSelected: isSelected,
                onTap: () {
                  AppHaptics.selectionClick(context);
                  setState(() => _selectedYear = year);
                },
                isDark: isDark,
              ),
            );
          }),
          // Undated chip if present
          if (hasUndated)
            _buildYearChip(
              label: 'Undated',
              isSelected: _selectedYear == 'Undated',
              onTap: () {
                AppHaptics.selectionClick(context);
                setState(() => _selectedYear = 'Undated');
              },
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildYearChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.champagneGold
              : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.champagneGold
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }
}
