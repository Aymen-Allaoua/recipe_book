import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'database/database_helper.dart';
import 'screens/home_page.dart';
import 'screens/favorites_page.dart';
import 'screens/search_page.dart';
import 'screens/recipe_details_page.dart';
import 'screens/add_edit_recipe_page.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. نفتح قاعدة البيانات
  await DatabaseHelper.instance.database;
  
  // 2. نفعّل Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 3. SharedPreferences للـ Dark Mode
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(isDark),
      child: const RecipeBookApp(),
    ),
  );
}

class RecipeBookApp extends StatelessWidget {
  const RecipeBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'كتاب الوصفات',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.red,
            scaffoldBackgroundColor: Colors.grey[50],
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.red,
            scaffoldBackgroundColor: Colors.grey[900],
            cardTheme: CardTheme(
              elevation: 2,
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const HomePage(),
            '/favorites': (context) => const FavoritesPage(),
            '/search': (context) => const SearchPage(),
            '/details': (context) => const RecipeDetailsPage(),
            '/add-edit': (context) => const AddEditRecipePage(),
          },
        );
      },
    );
  }
}
