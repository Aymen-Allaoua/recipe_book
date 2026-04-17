import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.home,
              color: currentIndex == 0 ? Theme.of(context).primaryColor : null,
            ),
            onPressed: () {
              if (currentIndex != 0) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: currentIndex == 1 ? Theme.of(context).primaryColor : null,
            ),
            onPressed: () {
              if (currentIndex != 1) {
                Navigator.pushReplacementNamed(context, '/favorites');
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: currentIndex == 2 ? Theme.of(context).primaryColor : null,
            ),
            onPressed: () {
              if (currentIndex != 2) {
                Navigator.pushReplacementNamed(context, '/search');
              }
            },
          ),
          IconButton(
            icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
    );
  }
}
