// lib/widgets/recipe_card.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onLongPress,
  });

  // دالة عرض الصورة المحلية أو placeholder
  Widget _buildLocalOrPlaceholder() {
    if (recipe.imagePath != null && File(recipe.imagePath!).existsSync()) {
      return Image.file(
        File(recipe.imagePath!),
        fit: BoxFit.cover,
      );
    }
    return Container(
      color: Colors.red.shade400,
      child: const Icon(
        Icons.restaurant_menu,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  // دالة عرض الصورة (Firebase → محلية → placeholder)
  Widget _buildImage() {
    if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
      return Image.network(
        recipe.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildLocalOrPlaceholder(),
      );
    }
    return _buildLocalOrPlaceholder();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1.0, // أفضل نسبة للصورة
                child: _buildImage(),
              ),
            ),

            // النصوص + القلب في الأسفل دائمًا
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان (سطرين كحد أقصى)
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // التصنيف
                  Text(
                    recipe.category,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),

                  // السحر: Spacer يدفع القلب للأسفل مهما كان الطول
                  const Spacer(),

                  // القلب في الأسفل دائمًا
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      recipe.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: recipe.isFavorite ? Colors.red : Colors.grey,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
