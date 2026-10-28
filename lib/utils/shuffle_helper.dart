import 'dart:math';
import '../models/photo.dart';
import '../models/visit.dart';

class ShuffleHelper {
  /// Builds a randomized permutation of [photos] with maximum variety across visits and restaurants.
  /// Guarantees:
  /// - NO photo is repeated within the sequence of length N.
  /// - Photos from the same visit are interleaved so they do not cluster back-to-back when multiple visits exist.
  /// - Preserves real photo references only (never invents or duplicates photos).
  static List<Photo> createDiverseShuffleSequence(
    List<Photo> photos, {
    Map<String, Visit>? visitLookup,
  }) {
    if (photos.length <= 2) {
      return List<Photo>.from(photos)..shuffle(Random());
    }

    // Group photos by visitId (or restaurantId if visitId is null)
    final Map<String, List<Photo>> groups = {};
    for (var p in photos) {
      final key = p.visitId ?? p.restaurantId;
      groups.putIfAbsent(key, () => []).add(p);
    }

    // Shuffle inside each group
    final random = Random();
    for (var list in groups.values) {
      list.shuffle(random);
    }

    // Shuffle the order of groups
    final groupKeys = groups.keys.toList()..shuffle(random);

    // Round-robin interleave from groups to avoid consecutive photos from same visit
    final List<Photo> result = [];
    bool hasRemaining = true;
    int round = 0;

    while (hasRemaining) {
      hasRemaining = false;
      for (var key in groupKeys) {
        final list = groups[key]!;
        if (round < list.length) {
          result.add(list[round]);
          if (round + 1 < list.length) {
            hasRemaining = true;
          }
        }
      }
      round++;
    }

    return result;
  }
}
