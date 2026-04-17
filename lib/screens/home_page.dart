import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import '../widgets/bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Recipe> _recipes = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    final all = await _dbHelper.getAllRecipes();

    List<Recipe> filtered;
    if (_selectedCategory == 'all') {
      filtered = all;
    } else {
      filtered = all.where((r) => r.category == _selectedCategory).toList();
    }

    setState(() {
      _recipes = filtered;
      _isLoading = false;
    });
  }

  void _showOptions(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
                recipe.isFavorite ? Icons.favorite : Icons.favorite_border),
            title:
                Text(recipe.isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة'),
            onTap: () async {
              Navigator.pop(context);
              await _dbHelper.toggleFavorite(
                  recipe.id.toString(), recipe.isFavorite);
              _loadRecipes();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title:
                const Text('حذف الوصفة', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final c = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('تأكيد الحذف'),
                  content: Text('حذف "${recipe.title}" نهائيًا؟'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('لا')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('نعم',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (c == true) {
                await _dbHelper.deleteRecipe(recipe.id.toString());
                _loadRecipes();
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
      appBar: AppBar(title: const Text('كتاب الوصفات'), centerTitle: true),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              children: [
                _chip('all', 'الكل'),
                _chip('أطباق رئيسية', 'أطباق رئيسية'),
                _chip('وجبات سريعة', 'وجبات سريعة'),
                _chip('حلويات', 'حلويات'),
                _chip('مشروبات', 'مشروبات'),
                _chip('مقبلات', 'مقبلات'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recipes.isEmpty
                    ? const Center(child: Text('لا توجد وصفات'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _recipes.length,
                        itemBuilder: (_, i) => RecipeCard(
                          recipe: _recipes[i],
                          onTap: () => Navigator.pushNamed(context, '/details',
                                  arguments: _recipes[i])
                              .then((_) => _loadRecipes()),
                          onLongPress: () => _showOptions(_recipes[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-edit')
            .then((_) => _loadRecipes()),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _chip(String value, String label) {
    final selected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: Colors.red.shade400,
        labelStyle: TextStyle(color: selected ? Colors.white : null),
        onSelected: (_) {
          setState(() => _selectedCategory = value);
          _loadRecipes();
        },
      ),
    );
  }
}
