// lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/recipe.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recipes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recipes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        ingredients TEXT NOT NULL DEFAULT '',
        steps TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT 'غير مصنف',
        imagePath TEXT,
        imageUrl TEXT,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        syncedAt TEXT
      )
    ''');

    // ignore: avoid_print
    print("تم إنشاء جدول recipes");
    await _insertSampleRecipes(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE recipes ADD COLUMN ingredients TEXT DEFAULT ""');
      await db.execute('ALTER TABLE recipes ADD COLUMN steps TEXT DEFAULT ""');
      await db.execute('ALTER TABLE recipes ADD COLUMN imageUrl TEXT');
      await db.execute('ALTER TABLE recipes ADD COLUMN createdAt TEXT');
      await db.execute('ALTER TABLE recipes ADD COLUMN syncedAt TEXT');

      await db.execute('''
        UPDATE recipes 
        SET ingredients = COALESCE(keywords, ''),
            steps = REPLACE(steps, '\n', '|||'),
            createdAt = datetime('now')
      ''');

      // نضيف الوصفات التجريبية لو القاعدة فاضية
      final count = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM recipes')) ??
          0;
      if (count == 0) {
        await _insertSampleRecipes(db);
      }
    }
  }

  // ← أهم دالة: نضيف الوصفات التجريبية دائمًا إذا كانت القاعدة فاضية
  Future _insertSampleRecipes(Database db) async {
    final samples = [
      {
        'title': 'كبسة دجاج',
        'ingredients':
            'أرز بسمتي|||دجاج|||طماطم|||بصل|||بهارات كبسة|||زيت|||ملح',
        'steps':
            'اغسل الأرز وانقعه 30 دقيقة|||قلّي البصل|||أضف الدجاج|||أضف الطماطم والبهارات|||أضف الأرز والماء واتركه ينضج',
        'category': 'أطباق رئيسية', // ← تم التصحيح
        'imagePath': 'assets/placeholder.png',
        'isFavorite': 1,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'title': 'كيكة الشوكولاتة',
        'ingredients': 'دقيق|||سكر|||كاكاو|||بيض|||زبدة|||حليب|||بيكنج باودر',
        'steps':
            'اخلط المكونات الجافة|||أضف البيض والزبدة|||اخلط جيدًا|||صب في الصينية|||اخبز 35 دقيقة',
        'category': 'حلويات',
        'imagePath': 'assets/placeholder.png',
        'isFavorite': 0,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'title': 'برجر لحم',
        'ingredients':
            'لحم مفروم|||بصل|||ثوم|||ملح|||فلفل أسود|||خبز برجر|||جبن',
        'steps':
            'اخلط اللحم مع التوابل|||شكّل أقراص|||اشوي 5 دقائق لكل جهة|||أضف الجبن|||ضعه في الخبز',
        'category': 'وجبات سريعة',
        'imagePath': 'assets/placeholder.png',
        'isFavorite': 1,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];

    for (var sample in samples) {
      await db.insert('recipes', sample,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    // ignore: avoid_print
    print("تم إضافة ${samples.length} وصفات تجريبية");
  }

  // باقي الدوال (نفس ما هي)
  Future<int> insertRecipe(Recipe recipe) async {
    final db = await database;
    return await db.insert('recipes', recipe.toSqfliteMap());
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final result = await db.query('recipes', orderBy: 'createdAt DESC');
    return result
        .map((map) => Recipe.fromSqfliteMap(map, map['id'].toString()))
        .toList();
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    final db = await database;
    final result = await db.query('recipes', where: 'isFavorite = 1');
    return result
        .map((map) => Recipe.fromSqfliteMap(map, map['id'].toString()))
        .toList();
  }

  Future<Recipe?> getRecipeById(String id) async {
    final db = await database;
    final result = await db.query('recipes', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return Recipe.fromSqfliteMap(result.first, id);
    return null;
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final db = await database;
    return await db.update('recipes', recipe.toSqfliteMap(),
        where: 'id = ?', whereArgs: [recipe.id]);
  }

  Future<int> deleteRecipe(String id) async {
    final db = await database;
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleFavorite(String id, bool current) async {
    final db = await database;
    return await db.update('recipes', {'isFavorite': current ? 0 : 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Recipe>> getRecipesNeedSync() async {
    final db = await database;
    final result = await db.query('recipes',
        where: 'syncedAt IS NULL OR syncedAt < createdAt');
    return result
        .map((map) => Recipe.fromSqfliteMap(map, map['id'].toString()))
        .toList();
  }

  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update('recipes', {'syncedAt': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  Future close() async => (await database).close();
}
