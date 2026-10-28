import 'package:uuid/uuid.dart';

class Restaurant {
  final String id;
  final String name;
  final String normalizedName;
  final String? location;
  final String? cuisine;
  final String? mapsUrl;
  final String? website;
  final String? phone;
  final int? priceRange; // 1 to 4
  final String? coverPhotoPath;
  final String? description;
  final List<String> tags;
  final bool isFavorite;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Restaurant({
    String? id,
    required this.name,
    String? normalizedName,
    this.location,
    this.cuisine,
    this.mapsUrl,
    this.website,
    this.phone,
    this.priceRange,
    this.coverPhotoPath,
    this.description,
    List<String>? tags,
    this.isFavorite = false,
    this.isArchived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        normalizedName = normalizedName ?? _normalize(name),
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? normalizedName,
    String? location,
    String? cuisine,
    String? mapsUrl,
    String? website,
    String? phone,
    int? priceRange,
    String? coverPhotoPath,
    String? description,
    List<String>? tags,
    bool? isFavorite,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? (name != null ? _normalize(name) : this.normalizedName),
      location: location ?? this.location,
      cuisine: cuisine ?? this.cuisine,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      priceRange: priceRange ?? this.priceRange,
      coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
      description: description ?? this.description,
      tags: tags ?? List.from(this.tags),
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'normalizedName': normalizedName,
      'location': location,
      'cuisine': cuisine,
      'mapsUrl': mapsUrl,
      'website': website,
      'phone': phone,
      'priceRange': priceRange,
      'coverPhotoPath': coverPhotoPath,
      'description': description,
      'tags': tags.join(','),
      'isFavorite': isFavorite ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String? ?? '';
    final tagsList = tagsStr.isEmpty ? <String>[] : tagsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Restaurant(
      id: map['id'] as String,
      name: map['name'] as String,
      normalizedName: map['normalizedName'] as String?,
      location: map['location'] as String?,
      cuisine: map['cuisine'] as String?,
      mapsUrl: map['mapsUrl'] as String?,
      website: map['website'] as String?,
      phone: map['phone'] as String?,
      priceRange: map['priceRange'] as int?,
      coverPhotoPath: map['coverPhotoPath'] as String?,
      description: map['description'] as String?,
      tags: tagsList,
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'normalizedName': normalizedName,
      'location': location,
      'cuisine': cuisine,
      'mapsUrl': mapsUrl,
      'website': website,
      'phone': phone,
      'priceRange': priceRange,
      'coverPhotoPath': coverPhotoPath,
      'description': description,
      'tags': tags,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Untitled Place',
      normalizedName: json['normalizedName'] as String?,
      location: json['location'] as String?,
      cuisine: json['cuisine'] as String?,
      mapsUrl: json['mapsUrl'] as String?,
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      priceRange: (json['priceRange'] as num?)?.toInt(),
      coverPhotoPath: json['coverPhotoPath'] as String?,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
