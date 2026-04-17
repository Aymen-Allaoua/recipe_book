import 'package:flutter/material.dart';
import 'dart:io';
import '../models/recipe.dart';
import '../database/database_helper.dart';

class RecipeDetailsPage extends StatefulWidget {
  const RecipeDetailsPage({super.key});

  @override
  State<RecipeDetailsPage> createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late Recipe _recipe;

  Future<void> _toggleFavorite() async {
    final newStatus = !_recipe.isFavorite;
    await _dbHelper.toggleFavorite(_recipe.id.toString(), _recipe.isFavorite);
    setState(() {
      _recipe = _recipe.copyWith(isFavorite: newStatus);
    });
  }

  Future<void> _deleteRecipe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف وصفة "${_recipe.title}" نهائيًا؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteRecipe(_recipe.id.toString());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الوصفة بنجاح')),
        );
      }
    }
  }

  Widget _buildImage() {
    // الأولوية: الصورة من Firebase → الصورة المحلية → Placeholder
    if (_recipe.imageUrl != null && _recipe.imageUrl!.isNotEmpty) {
      return Image.network(
        _recipe.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildLocalOrPlaceholder(),
      );
    }
    return _buildLocalOrPlaceholder();
  }

  Widget _buildLocalOrPlaceholder() {
    if (_recipe.imagePath != null && File(_recipe.imagePath!).existsSync()) {
      return Image.file(File(_recipe.imagePath!), fit: BoxFit.cover);
    }
    return Container(
      color: Colors.red.shade400,
      child: const Icon(Icons.restaurant_menu, size: 90, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    _recipe = ModalRoute.of(context)!.settings.arguments as Recipe;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImage(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _recipe.isFavorite ? Colors.red : Colors.white,
                  size: 28,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/add-edit',
                    arguments: _recipe,
                  );
                  if (result == true) {
                    final updated =
                        await _dbHelper.getRecipeById(_recipe.id.toString());
                    if (updated != null && mounted) {
                      setState(() => _recipe = updated);
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _deleteRecipe,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان والتصنيف
                  Text(
                    _recipe.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    backgroundColor: Colors.red.shade100,
                    label: Text(
                      _recipe.category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // المكونات
                  Text(
                    'المكونات',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ..._recipe.ingredients.map((ing) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.circle,
                                size: 10, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(ing,
                                    style: const TextStyle(fontSize: 16))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),

                  // الخطوات
                  Text(
                    'طريقة التحضير',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ..._recipe.steps.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$index',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
