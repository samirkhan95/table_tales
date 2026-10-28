import 'package:uuid/uuid.dart';

class Photo {
  final String id;
  final String restaurantId;
  final String? visitId;
  final String filePath;
  final String? caption;
  final int sortOrder;
  final DateTime createdAt;

  Photo({
    String? id,
    required this.restaurantId,
    this.visitId,
    required this.filePath,
    this.caption,
    this.sortOrder = 0,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Photo copyWith({
    String? id,
    String? restaurantId,
    String? visitId,
    String? filePath,
    String? caption,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Photo(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      visitId: visitId ?? this.visitId,
      filePath: filePath ?? this.filePath,
      caption: caption ?? this.caption,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'visitId': visitId,
      'filePath': filePath,
      'caption': caption,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] as String,
      restaurantId: map['restaurantId'] as String,
      visitId: map['visitId'] as String?,
      filePath: map['filePath'] as String? ?? '',
      caption: map['caption'] as String?,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'visitId': visitId,
      'filePath': filePath,
      'caption': caption,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String? ?? const Uuid().v4(),
      restaurantId: json['restaurantId'] as String? ?? '',
      visitId: json['visitId'] as String?,
      filePath: json['filePath'] as String? ?? '',
      caption: json['caption'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
