import 'package:uuid/uuid.dart';

class Visit {
  final String id;
  final String restaurantId;
  final DateTime? visitDate;
  final bool isApproximateDate;
  final String? mealType; // Breakfast, Lunch, Dinner, Drinks, Late Night, Coffee & Bakery, Dessert
  final String? occasion; // Date Night, Anniversary, Birthday, Weekend Getaway, Celebration, Casual, etc.
  final String? notes;
  final double? rating; // 1.0 to 5.0
  final double? amountSpent;
  final String? currency;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Visit({
    String? id,
    required this.restaurantId,
    this.visitDate,
    this.isApproximateDate = false,
    this.mealType,
    this.occasion,
    this.notes,
    this.rating,
    this.amountSpent,
    this.currency,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Visit copyWith({
    String? id,
    String? restaurantId,
    DateTime? visitDate,
    bool? isApproximateDate,
    String? mealType,
    String? occasion,
    String? notes,
    double? rating,
    double? amountSpent,
    String? currency,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Visit(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      visitDate: visitDate ?? this.visitDate,
      isApproximateDate: isApproximateDate ?? this.isApproximateDate,
      mealType: mealType ?? this.mealType,
      occasion: occasion ?? this.occasion,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      amountSpent: amountSpent ?? this.amountSpent,
      currency: currency ?? this.currency,
      tags: tags ?? List.from(this.tags),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'visitDate': visitDate?.toIso8601String(),
      'isApproximateDate': isApproximateDate ? 1 : 0,
      'mealType': mealType,
      'occasion': occasion,
      'notes': notes,
      'rating': rating,
      'amountSpent': amountSpent,
      'currency': currency,
      'tags': tags.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String? ?? '';
    final tagsList = tagsStr.isEmpty ? <String>[] : tagsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Visit(
      id: map['id'] as String,
      restaurantId: map['restaurantId'] as String,
      visitDate: map['visitDate'] != null ? DateTime.tryParse(map['visitDate'] as String) : null,
      isApproximateDate: (map['isApproximateDate'] as int? ?? 0) == 1,
      mealType: map['mealType'] as String?,
      occasion: map['occasion'] as String?,
      notes: map['notes'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
      amountSpent: (map['amountSpent'] as num?)?.toDouble(),
      currency: map['currency'] as String?,
      tags: tagsList,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'visitDate': visitDate?.toIso8601String(),
      'isApproximateDate': isApproximateDate,
      'mealType': mealType,
      'occasion': occasion,
      'notes': notes,
      'rating': rating,
      'amountSpent': amountSpent,
      'currency': currency,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'] as String? ?? const Uuid().v4(),
      restaurantId: json['restaurantId'] as String? ?? '',
      visitDate: json['visitDate'] != null ? DateTime.tryParse(json['visitDate'] as String) : null,
      isApproximateDate: json['isApproximateDate'] as bool? ?? false,
      mealType: json['mealType'] as String?,
      occasion: json['occasion'] as String?,
      notes: json['notes'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      amountSpent: (json['amountSpent'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
