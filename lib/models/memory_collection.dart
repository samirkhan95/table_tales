import '../models/photo.dart';

enum CollectionType {
  allAdventures,
  year,
  occasion,
  favorites,
  recent,
}

class MemoryCollection {
  final String id;
  final String title;
  final String subtitle;
  final String coverPhotoPath;
  final int count;
  final CollectionType type;
  final int? year;
  final String? occasion;
  final List<Photo> photos;

  const MemoryCollection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverPhotoPath,
    required this.count,
    required this.type,
    this.year,
    this.occasion,
    required this.photos,
  });
}
