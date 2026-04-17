import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import '../widgets/bottom_nav_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _controller = TextEditingController();
  List<Recipe> _results = [];
  bool _loading = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final all = await _dbHelper.getAllRecipes();
    final query = q.toLowerCase();
    final filtered = all
        .where((r) =>
            r.title.toLowerCase().contains(query) ||
            r.ingredients.any((i) => i.toLowerCase().contains(query)) ||
            r.category.toLowerCase().contains(query))
        .toList();
    setState(() {
      _results = filtered;
      _loading = false;
    });
  }

  void _options(Recipe r) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading:
                Icon(r.isFavorite ? Icons.favorite : Icons.favorite_border),
            title: Text(r.isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة'),
            onTap: () async {
              Navigator.pop(context);
              await _dbHelper.toggleFavorite(r.id.toString(), r.isFavorite);
              _search(_controller.text);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('حذف', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              if (await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: const Text('تأكيد'),
                            content: Text('حذف "${r.title}"؟'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('لا')),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('نعم'))
                            ],
                          )) ==
                  true) {
                await _dbHelper.deleteRecipe(r.id.toString());
                _search(_controller.text);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'ابحث...', border: InputBorder.none),
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _search(_controller.text))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(child: Text('اكتب شيء للبحث'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.70,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16),
                  itemCount: _results.length,
                  itemBuilder: (_, i) => RecipeCard(
                    recipe: _results[i],
                    onTap: () => Navigator.pushNamed(context, '/details',
                            arguments: _results[i])
                        .then((_) => _search(_controller.text)),
                    onLongPress: () => _options(_results[i]),
                  ),
                ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }
}
