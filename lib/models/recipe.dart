// lib/models/recipe.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String? id;
  final String title;
  final List<String> ingredients;
  final List<String> steps;
  final String category;
  final String? imagePath;
  final String? imageUrl;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? syncedAt;

  Recipe({
    this.id,
    required this.title,
    List<String>? ingredients,
    List<String>? steps,
    this.category = 'غير مصنف',
    this.imagePath,
    this.imageUrl,
    this.isFavorite = false,
    DateTime? createdAt,
    this.syncedAt,
  }) : ingredients = ingredients ?? [],
       steps = steps ?? [],
       createdAt = createdAt ?? DateTime.now();

  factory Recipe.fromSqfliteMap(Map<String, dynamic> map, String id) {
    return Recipe(
      id: id,
      title: map['title'] ?? '',
      ingredients: (map['ingredients'] as String?)?.split('|||') ?? [],
      steps: (map['steps'] as String?)?.split('|||') ?? [],
      category: map['category'] ?? 'غير مصنف',
      imagePath: map['imagePath'],
      imageUrl: map['imageUrl'],
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      syncedAt:
          map['syncedAt'] != null ? DateTime.parse(map['syncedAt']) : null,
    );
  }

  Map<String, dynamic> toSqfliteMap() {
    return {
      'title': title,
      'ingredients': ingredients.join('|||'),
      'steps': steps.join('|||'),
      'category': category,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'ingredients': ingredients,
      'steps': steps,
      'category': category,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      steps: List<String>.from(data['steps'] ?? []),
      category: data['category'] ?? 'غير مصنف',
      imageUrl: data['imageUrl'],
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      syncedAt:
          data['syncedAt'] != null
              ? (data['syncedAt'] as Timestamp).toDate()
              : null,
    );
  }

  Recipe copyWith({
    String? id,
    String? title,
    List<String>? ingredients,
    List<String>? steps,
    String? category,
    String? imagePath,
    String? imageUrl,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? syncedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  bool get needsSync => syncedAt == null || syncedAt!.isBefore(createdAt);
}
