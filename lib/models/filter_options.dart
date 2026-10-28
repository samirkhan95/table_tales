import 'package:flutter/material.dart';

class FilterOptions {
  final String searchQuery;
  final bool onlyFavorites;
  final bool onlyHasPhotos;
  final List<String> selectedCuisines;
  final List<String> selectedTags;
  final int? minVisits;
  final DateTimeRange? dateRange;
  final String sortBy; // "recent", "visits", "name", "rating", "favorites"

  const FilterOptions({
    this.searchQuery = '',
    this.onlyFavorites = false,
    this.onlyHasPhotos = false,
    this.selectedCuisines = const [],
    this.selectedTags = const [],
    this.minVisits,
    this.dateRange,
    this.sortBy = 'recent',
  });

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        onlyFavorites ||
        onlyHasPhotos ||
        selectedCuisines.isNotEmpty ||
        selectedTags.isNotEmpty ||
        minVisits != null ||
        dateRange != null;
  }

  int get activeFilterCount {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    if (onlyFavorites) count++;
    if (onlyHasPhotos) count++;
    if (selectedCuisines.isNotEmpty) count += selectedCuisines.length;
    if (selectedTags.isNotEmpty) count += selectedTags.length;
    if (minVisits != null) count++;
    if (dateRange != null) count++;
    return count;
  }

  FilterOptions copyWith({
    String? searchQuery,
    bool? onlyFavorites,
    bool? onlyHasPhotos,
    List<String>? selectedCuisines,
    List<String>? selectedTags,
    int? minVisits,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? sortBy,
  }) {
    return FilterOptions(
      searchQuery: searchQuery ?? this.searchQuery,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      onlyHasPhotos: onlyHasPhotos ?? this.onlyHasPhotos,
      selectedCuisines: selectedCuisines ?? List.from(this.selectedCuisines),
      selectedTags: selectedTags ?? List.from(this.selectedTags),
      minVisits: minVisits ?? this.minVisits,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  FilterOptions reset() {
    return FilterOptions(sortBy: sortBy);
  }
}
