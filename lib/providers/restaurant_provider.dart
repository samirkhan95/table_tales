import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../models/visit.dart';
import '../models/photo.dart';
import '../models/filter_options.dart';
import '../services/database_service.dart';
import '../services/photo_storage_service.dart';
import '../services/sample_data_service.dart';

class RestaurantProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final PhotoStorageService _photoStorage = PhotoStorageService();

  List<Restaurant> _restaurants = [];
  List<Visit> _visits = [];
  List<Photo> _photos = [];

  FilterOptions _filterOptions = const FilterOptions();
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Restaurant> get allRestaurants => _restaurants;
  List<Visit> get allVisits => _visits;
  List<Photo> get allPhotos => _photos;
  FilterOptions get filterOptions => _filterOptions;

  RestaurantProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _restaurants = await _dbService.getAllRestaurants();
      _visits = await _dbService.getAllVisits();
      _photos = await _dbService.getAllPhotos();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FILTERED & SORTED RESTAURANTS ---

  List<Restaurant> get filteredRestaurants {
    return _restaurants.where((r) {
      // Search query
      if (_filterOptions.searchQuery.isNotEmpty) {
        final query = _filterOptions.searchQuery.toLowerCase();
        final nameMatch = r.name.toLowerCase().contains(query);
        final locMatch = r.location?.toLowerCase().contains(query) ?? false;
        final cuisMatch = r.cuisine?.toLowerCase().contains(query) ?? false;
        final tagsMatch = r.tags.any((t) => t.toLowerCase().contains(query));

        // Visit notes match
        final rVisits = getVisitsForRestaurant(r.id);
        final notesMatch = rVisits.any((v) => v.notes?.toLowerCase().contains(query) ?? false);

        if (!nameMatch && !locMatch && !cuisMatch && !tagsMatch && !notesMatch) {
          return false;
        }
      }

      // Favorites
      if (_filterOptions.onlyFavorites && !r.isFavorite) {
        return false;
      }

      // Has Photos
      if (_filterOptions.onlyHasPhotos) {
        final rPhotos = getPhotosForRestaurant(r.id);
        if (rPhotos.isEmpty) return false;
      }

      // Cuisine filter
      if (_filterOptions.selectedCuisines.isNotEmpty) {
        if (r.cuisine == null || !_filterOptions.selectedCuisines.contains(r.cuisine)) {
          return false;
        }
      }

      // Tags filter
      if (_filterOptions.selectedTags.isNotEmpty) {
        final hasAnyTag = _filterOptions.selectedTags.any((t) => r.tags.contains(t));
        if (!hasAnyTag) return false;
      }

      // Minimum visits
      if (_filterOptions.minVisits != null) {
        final vCount = getVisitCountForRestaurant(r.id);
        if (vCount < _filterOptions.minVisits!) return false;
      }

      // Date Range filter
      if (_filterOptions.dateRange != null) {
        final rVisits = getVisitsForRestaurant(r.id);
        final inRange = rVisits.any((v) {
          if (v.visitDate == null) return false;
          return v.visitDate!.isAfter(_filterOptions.dateRange!.start.subtract(const Duration(days: 1))) &&
              v.visitDate!.isBefore(_filterOptions.dateRange!.end.add(const Duration(days: 1)));
        });
        if (!inRange) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        switch (_filterOptions.sortBy) {
          case 'visits':
            final countA = getVisitCountForRestaurant(a.id);
            final countB = getVisitCountForRestaurant(b.id);
            return countB.compareTo(countA);
          case 'name':
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case 'favorites':
            if (a.isFavorite != b.isFavorite) {
              return a.isFavorite ? -1 : 1;
            }
            return a.name.compareTo(b.name);
          case 'rating':
            final ratingA = getAverageRatingForRestaurant(a.id) ?? 0;
            final ratingB = getAverageRatingForRestaurant(b.id) ?? 0;
            return ratingB.compareTo(ratingA);
          case 'recent':
          default:
            final lastA = getMostRecentVisitDate(a.id) ?? a.createdAt;
            final lastB = getMostRecentVisitDate(b.id) ?? b.createdAt;
            return lastB.compareTo(lastA);
        }
      });
  }

  void updateFilter(FilterOptions newFilter) {
    _filterOptions = newFilter;
    notifyListeners();
  }

  void resetFilters() {
    _filterOptions = const FilterOptions();
    notifyListeners();
  }

  // --- DYNAMIC CALCULATED HELPERS ---

  int getVisitCountForRestaurant(String restaurantId) {
    return _visits.where((v) => v.restaurantId == restaurantId).length;
  }

  List<Visit> getVisitsForRestaurant(String restaurantId) {
    final list = _visits.where((v) => v.restaurantId == restaurantId).toList();
    list.sort((a, b) {
      if (a.visitDate == null && b.visitDate == null) return 0;
      if (a.visitDate == null) return 1;
      if (b.visitDate == null) return -1;
      return b.visitDate!.compareTo(a.visitDate!);
    });
    return list;
  }

  List<Photo> getPhotosForRestaurant(String restaurantId) {
    return _photos.where((p) => p.restaurantId == restaurantId).toList();
  }

  List<Photo> getPhotosForVisit(String visitId) {
    return _photos.where((p) => p.visitId == visitId).toList();
  }

  DateTime? getMostRecentVisitDate(String restaurantId) {
    final rVisits = getVisitsForRestaurant(restaurantId);
    for (var v in rVisits) {
      if (v.visitDate != null) return v.visitDate;
    }
    return null;
  }

  DateTime? getFirstVisitDate(String restaurantId) {
    final rVisits = getVisitsForRestaurant(restaurantId);
    DateTime? first;
    for (var v in rVisits) {
      if (v.visitDate != null) {
        if (first == null || v.visitDate!.isBefore(first)) {
          first = v.visitDate;
        }
      }
    }
    return first;
  }

  double? getAverageRatingForRestaurant(String restaurantId) {
    final rVisits = getVisitsForRestaurant(restaurantId).where((v) => v.rating != null).toList();
    if (rVisits.isEmpty) return null;
    final total = rVisits.fold<double>(0, (sum, v) => sum + v.rating!);
    return total / rVisits.length;
  }

  Restaurant? get featuredMemoryRestaurant {
    if (_restaurants.isEmpty) return null;
    final favs = _restaurants.where((r) => r.isFavorite).toList();
    if (favs.isNotEmpty) return favs.first;
    return _restaurants.first;
  }

  Visit? getVisitById(String? visitId) {
    if (visitId == null) return null;
    for (var v in _visits) {
      if (v.id == visitId) return v;
    }
    return null;
  }

  Restaurant? getRestaurantById(String? restaurantId) {
    if (restaurantId == null) return null;
    for (var r in _restaurants) {
      if (r.id == restaurantId) return r;
    }
    return null;
  }

  /// Strictly returns unique occasions explicitly recorded in existing visits.
  /// Never invents or hardcodes unrecorded occasions.
  List<String> get recordedOccasions {
    final Set<String> occasions = {};
    for (var v in _visits) {
      if (v.occasion != null && v.occasion!.trim().isNotEmpty) {
        occasions.add(v.occasion!.trim());
      }
    }
    return occasions.toList()..sort();
  }

  // --- STATISTICS HELPERS ---

  int get totalUniqueRestaurants => _restaurants.length;
  int get totalRecordedVisits => _visits.length;
  int get totalPhotosCount => _photos.length;

  double get avgVisitsPerRestaurant {
    if (_restaurants.isEmpty) return 0;
    return _visits.length / _restaurants.length;
  }

  Restaurant? get mostVisitedRestaurant {
    if (_restaurants.isEmpty) return null;
    Restaurant? best;
    int maxCount = -1;
    for (var r in _restaurants) {
      final c = getVisitCountForRestaurant(r.id);
      if (c > maxCount) {
        maxCount = c;
        best = r;
      }
    }
    return best;
  }

  /// Returns top 3 most visited restaurants sorted by visit count descending.
  List<Restaurant> get topVisitedRestaurants {
    final list = List<Restaurant>.from(_restaurants);
    list.sort((a, b) {
      final countA = getVisitCountForRestaurant(a.id);
      final countB = getVisitCountForRestaurant(b.id);
      if (countA == countB) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return countB.compareTo(countA);
    });
    final withVisits = list.where((r) => getVisitCountForRestaurant(r.id) > 0).toList();
    return withVisits.take(3).toList();
  }

  Map<String, int> get cuisineDistribution {
    Map<String, int> counts = {};
    for (var r in _restaurants) {
      final cuisine = (r.cuisine == null || r.cuisine!.trim().isEmpty) ? 'Other' : r.cuisine!.trim();
      counts[cuisine] = (counts[cuisine] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get occasionDistribution {
    Map<String, int> counts = {};
    for (var v in _visits) {
      final occ = (v.occasion == null || v.occasion!.trim().isEmpty) ? 'General' : v.occasion!.trim();
      counts[occ] = (counts[occ] ?? 0) + 1;
    }
    return counts;
  }

  List<String> get availableCuisines {
    final set = <String>{};
    for (var r in _restaurants) {
      if (r.cuisine != null && r.cuisine!.trim().isNotEmpty) {
        set.add(r.cuisine!.trim());
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get availableTags {
    final set = <String>{};
    for (var r in _restaurants) {
      set.addAll(r.tags);
    }
    for (var v in _visits) {
      set.addAll(v.tags);
    }
    final list = set.toList()..sort();
    return list;
  }

  // --- ACTIONS: RESTAURANTS ---

  Future<Restaurant?> checkDuplicateRestaurant(String name, {String? location}) async {
    return await _dbService.findSimilarRestaurant(name, location: location);
  }

  Future<void> saveRestaurant(Restaurant restaurant, {List<String>? initialPhotoPaths}) async {
    final exists = _restaurants.any((r) => r.id == restaurant.id);
    if (exists) {
      await _dbService.updateRestaurant(restaurant);
    } else {
      await _dbService.insertRestaurant(restaurant);
    }

    if (initialPhotoPaths != null && initialPhotoPaths.isNotEmpty) {
      for (int i = 0; i < initialPhotoPaths.length; i++) {
        final photo = Photo(
          restaurantId: restaurant.id,
          filePath: initialPhotoPaths[i],
          sortOrder: i,
        );
        await _dbService.insertPhoto(photo);
      }
    }

    await loadData();
  }

  Future<void> toggleFavorite(String restaurantId) async {
    final r = _restaurants.firstWhere((element) => element.id == restaurantId);
    final updated = r.copyWith(isFavorite: !r.isFavorite);
    await _dbService.updateRestaurant(updated);
    await loadData();
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    final rPhotos = getPhotosForRestaurant(restaurantId);
    for (var p in rPhotos) {
      await _photoStorage.deletePhotoFile(p.filePath);
    }

    await _dbService.deleteRestaurant(restaurantId);
    await loadData();
  }

  // --- ACTIONS: VISITS ---

  Future<void> saveVisit(Visit visit, {List<Photo>? photosToSave, List<String>? photosToDelete}) async {
    final exists = _visits.any((v) => v.id == visit.id);
    if (exists) {
      await _dbService.updateVisit(visit);
    } else {
      await _dbService.insertVisit(visit);
    }

    if (photosToDelete != null) {
      for (var pId in photosToDelete) {
        final p = _photos.firstWhere((element) => element.id == pId, orElse: () => Photo(restaurantId: '', filePath: ''));
        if (p.filePath.isNotEmpty) {
          await _photoStorage.deletePhotoFile(p.filePath);
        }
        await _dbService.deletePhoto(pId);
      }
    }

    if (photosToSave != null) {
      for (var p in photosToSave) {
        await _dbService.insertPhoto(p);
      }
    }

    await loadData();
  }

  Future<void> deleteVisit(String visitId) async {
    final vPhotos = getPhotosForVisit(visitId);
    for (var p in vPhotos) {
      await _photoStorage.deletePhotoFile(p.filePath);
    }

    await _dbService.deleteVisit(visitId);
    await loadData();
  }

  // --- ACTIONS: PHOTOS ---

  Future<void> addPhotosToRestaurant(String restaurantId, List<String> photoPaths, {String? visitId}) async {
    for (int i = 0; i < photoPaths.length; i++) {
      final photo = Photo(
        restaurantId: restaurantId,
        visitId: visitId,
        filePath: photoPaths[i],
        sortOrder: i,
      );
      await _dbService.insertPhoto(photo);
    }
    await loadData();
  }

  Future<void> deletePhoto(String photoId) async {
    final photo = _photos.firstWhere((p) => p.id == photoId, orElse: () => Photo(restaurantId: '', filePath: ''));
    if (photo.filePath.isNotEmpty) {
      await _photoStorage.deletePhotoFile(photo.filePath);
    }
    await _dbService.deletePhoto(photoId);
    await loadData();
  }

  // --- SAMPLE DATA & CLEAR ---

  Future<void> loadSampleData() async {
    await SampleDataService.loadSampleData(_dbService);
    await loadData();
  }

  Future<void> clearAllData() async {
    for (var p in _photos) {
      await _photoStorage.deletePhotoFile(p.filePath);
    }
    await _dbService.clearAllData();
    await loadData();
  }
}
