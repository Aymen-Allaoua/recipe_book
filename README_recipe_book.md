# recipe_book 🍽️

> A cross-platform Flutter app for discovering, saving, and managing recipes — with a fully Arabic interface, Firebase cloud sync, and offline support.

---

## ✨ Features

- 📝 **Add recipes manually** — create your own recipes with ingredients, steps, and photos
- 🔍 **Search recipes** — quickly find recipes by name or ingredient
- ❤️ **Favorites** — save and access your favorite recipes at any time
- 📸 **Image upload** — attach photos to recipes via Firebase Storage
- ☁️ **Cloud sync** — data stored and synced in real-time with Firestore
- 📴 **Offline support** — browse saved recipes without an internet connection
- 🌐 **Cross-platform** — Android, iOS, Windows, Linux, macOS, Web

---

## 🛠️ Tech Stack

| Layer            | Technology                  |
|------------------|-----------------------------|
| Framework        | Flutter (Material 3)        |
| Language         | Dart                        |
| Database         | Cloud Firestore             |
| File Storage     | Firebase Storage            |
| Offline Support  | Firestore offline persistence |
| UI Language      | Arabic (RTL)                |

---

## 🏗️ Project Structure

```
lib/
├── main.dart
├── models/          # Recipe data models
├── services/        # Firestore & Storage services
├── screens/         # UI screens (home, detail, add, favorites)
├── widgets/         # Reusable UI components
└── utils/           # Helpers & constants
assets/
└── images/          # Local image assets
```

---

## 🚀 Getting Started

```bash
# Clone the repository
git clone https://github.com/Aymen-Allaoua/recipe_book.git
cd recipe_book

# Install dependencies
flutter pub get

# Run the app
flutter run
```

> Requires Flutter 3.x or later and a Firebase project configured with Firestore and Storage.

---

## 🌍 Localization

The app interface is fully in **Arabic** with RTL layout support.

---

## 📄 License

This project is open source. Feel free to fork and build upon it.
