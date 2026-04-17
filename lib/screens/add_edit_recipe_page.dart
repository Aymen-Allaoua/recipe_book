import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/recipe.dart';
import '../database/database_helper.dart';

class AddEditRecipePage extends StatefulWidget {
  final Recipe? existingRecipe;
  const AddEditRecipePage({super.key, this.existingRecipe});

  @override
  State<AddEditRecipePage> createState() => _AddEditRecipePageState();
}

class _AddEditRecipePageState extends State<AddEditRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _stepControllers = [];

  String _category = 'أطباق رئيسية';
  String? _localImagePath;
  String? _firebaseImageUrl;
  bool _isUploading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.existingRecipe != null;

    _titleController = TextEditingController(
      text: _isEditMode ? widget.existingRecipe!.title : '',
    );

    if (_isEditMode) {
      final recipe = widget.existingRecipe!;
      _category = recipe.category;
      _localImagePath = recipe.imagePath;
      _firebaseImageUrl = recipe.imageUrl;

      // ملء المكونات
      for (var ing in recipe.ingredients) {
        _ingredientControllers.add(TextEditingController(text: ing));
      }
      if (_ingredientControllers.isEmpty)
        _ingredientControllers.add(TextEditingController());

      // ملء الخطوات
      for (var step in recipe.steps) {
        _stepControllers.add(TextEditingController(text: step));
      }
      if (_stepControllers.isEmpty)
        _stepControllers.add(TextEditingController());
    } else {
      // إضافة سطر فارغ للمكونات والخطوات
      _ingredientControllers.add(TextEditingController());
      _stepControllers.add(TextEditingController());
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _localImagePath = image.path;
        _firebaseImageUrl = null; // الصورة القديمة هتتمسح لما نحفظ
      });
    }
  }

  Future<String?> _uploadImageToFirebase(String localPath) async {
    if (localPath.isEmpty || !File(localPath).existsSync()) return null;

    setState(() => _isUploading = true);
    try {
      final fileName = 'recipes/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(File(localPath));
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    // جمع المكونات والخطوات
    final ingredients = _ingredientControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final steps = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (ingredients.isEmpty || steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يجب إضافة مكون واحد على الأقل وخطوة واحدة')),
      );
      return;
    }

    String? imageUrl = _firebaseImageUrl;
    if (_localImagePath != null && File(_localImagePath!).existsSync()) {
      imageUrl = await _uploadImageToFirebase(_localImagePath!);
    }

    final recipe = Recipe(
      id: _isEditMode ? widget.existingRecipe!.id : null,
      title: _titleController.text.trim(),
      ingredients: ingredients,
      steps: steps,
      category: _category,
      imagePath: _localImagePath,
      imageUrl: imageUrl,
      isFavorite: _isEditMode ? widget.existingRecipe!.isFavorite : false,
    );

    if (_isEditMode) {
      await _dbHelper.updateRecipe(recipe);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الوصفة بنجاح')),
      );
    } else {
      await _dbHelper.insertRecipe(recipe);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة الوصفة بنجاح')),
      );
    }

    if (mounted) Navigator.pop(context, true); // true = تم الحفظ
  }

  Widget _buildListField({
    required String title,
    required List<TextEditingController> controllers,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...controllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '$title ${index + 1}',
                      prefixIcon: Icon(icon, size: 20),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                if (controllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () =>
                        setState(() => controllers.removeAt(index)),
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () =>
              setState(() => controllers.add(TextEditingController())),
          icon: const Icon(Icons.add),
          label: Text('إضافة $title أخرى'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل الوصفة' : 'إضافة وصفة جديدة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الصورة
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : _localImagePath != null &&
                              File(_localImagePath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(File(_localImagePath!),
                                  fit: BoxFit.cover),
                            )
                          : _firebaseImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(_firebaseImageUrl!,
                                      fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo,
                                        size: 60, color: Colors.grey[600]),
                                    const Text('اضغط لإضافة صورة',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                ),
              ),
              const SizedBox(height: 20),

              // اسم الوصفة
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'اسم الوصفة',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              // التصنيف
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                    labelText: 'التصنيف', border: OutlineInputBorder()),
                items: [
                  'أطباق رئيسية',
                  'وجبات سريعة',
                  'حلويات',
                  'مشروبات',
                  'مقبلات',
                  'غير مصنف',
                ]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 20),

              // المكونات
              _buildListField(
                title: 'المكونات',
                controllers: _ingredientControllers,
                icon: Icons.restaurant_menu,
              ),

              // الخطوات
              _buildListField(
                title: 'الخطوات',
                controllers: _stepControllers,
                icon: Icons.format_list_numbered,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isUploading ? null : _saveRecipe,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(_isEditMode ? 'حفظ التعديلات' : 'إضافة الوصفة',
                    style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var c in _ingredientControllers) {
      c.dispose();
    }
    for (var c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }
}
