# 🍽️ TableTales — Restaurant Diary & Culinary Journey Tracker

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Cross--Platform-green?style=for-the-badge&logo=android)](https://android.com)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM%20%2B%20Provider-orange?style=for-the-badge)](https://pub.dev/packages/provider)
[![Status](https://img.shields.io/badge/Build-Release%20Ready-brightgreen?style=for-the-badge)]()

**TableTales** is a beautifully crafted, privacy-first mobile app designed for food lovers and couples to log dining experiences, cherish culinary memories, track spending analytics, and organize favorite restaurants. Built with **Flutter**, **Provider**, and **SQLite**, TableTales delivers a smooth, glassmorphic UI with local-first data storage.

---

## 📱 Try the Live App (Release APK)

You can experience the fully compiled app directly on your Android device without building from source:

📥 **[Download Latest Release APK](https://github.com/YOUR_GITHUB_USERNAME/table_tales/releases/latest)**

> **Note for Reviewers & Recruiters:** This showcase repository highlights the architecture, design system, and core technical implementations of TableTales. The production-ready pre-built APK is provided above for full hands-on testing.

---

## ✨ Key Features

- 📖 **Culinary Diary & Memory Journal** — Record dining visits, photo memories, ratings, order details, and special moments.
- 🎨 **Glassmorphic & Material 3 UI** — Modern, fluid user interface with dynamic dark/light themes, custom design tokens, and glassmorphism styling.
- 📊 **Visual Analytics & Charts** — Detailed spending insights, cuisine breakdowns, and visit frequency powered by `fl_chart`.
- 🔍 **Interactive Search & Filtering** — Quick search across restaurants, cuisines, locations, and memory collections with interactive overlays.
- 📁 **Data Import & Export (CSV)** — Full data ownership with local CSV backup and restore capabilities.
- 🔒 **Local-First Privacy** — On-device SQLite database ensuring your dining memories remain private and secure.

---

## 📸 App Screenshots

| Home & Restaurants | Detailed Memory View | Analytics & Charts | Dark Mode UI |
| :---: | :---: | :---: | :---: |
| *(Add Screenshot)* | *(Add Screenshot)* | *(Add Screenshot)* | *(Add Screenshot)* |

---

## 🛠️ Tech Stack & Architecture

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** [`provider`](https://pub.dev/packages/provider)
- **Local Database:** [`sqflite`](https://pub.dev/packages/sqflite) & [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi)
- **Data Visualization:** [`fl_chart`](https://pub.dev/packages/fl_chart)
- **UI & Styling:** Custom Theme Engine, `google_fonts`, Material 3, Glassmorphism
- **Architecture Pattern:** Clean Layered Architecture (MVVM)

```
lib/
├── models/         # Data contracts & domain entities (Restaurant, Visit, Photo, Settings)
├── providers/      # Application state management (RestaurantProvider, SettingsProvider)
├── services/       # Database persistence, CSV backup, & photo storage services
├── screens/        # UI Views & Navigation controllers
├── theme/          # Design tokens, color palettes, and global app themes
├── utils/          # Formatters, haptics, and helper utilities
└── widgets/        # Reusable custom UI components (GlassContainer, SearchOverlay, Cards)
```

---

## 💡 Showcase Code Snippets

### Clean State Management (`RestaurantProvider`)
```dart
class RestaurantProvider extends ChangeNotifier {
  List<Restaurant> _restaurants = [];
  bool _isLoading = false;

  List<Restaurant> get restaurants => UnmodifiableListView(_restaurants);
  bool get isLoading => _isLoading;

  Future<void> loadRestaurants() async {
    _isLoading = true;
    notifyListeners();
    _restaurants = await DatabaseService.instance.getRestaurants();
    _isLoading = false;
    notifyListeners();
  }
}
```

### Custom Glassmorphic Container
```dart
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          color: Colors.white.withOpacity(opacity),
          child: child,
        ),
      ),
    );
  }
}
```

---

## 🚀 How to Build Release APK

To generate the release build for testing on Android:

```bash
# 1. Clean build artifacts
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build optimized Release APK
flutter build apk --release
```

The output binary will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 💼 Showcase Repository Notice

This repository serves as a **Portfolio & Architecture Showcase** for project evaluation. 

- Core UI widgets, data models, state providers, and design tokens are included to showcase code quality and engineering standards.
- Pre-built binary releases are available under the [Releases](https://github.com/YOUR_GITHUB_USERNAME/table_tales/releases) tab.

---

## 👤 Author

Developed by **Your Name / Developer Profile**  
- GitHub: [@YOUR_GITHUB_USERNAME](https://github.com/YOUR_GITHUB_USERNAME)  
- LinkedIn: [Your LinkedIn](https://linkedin.com/in/YOUR_PROFILE)  

---

*Made with ❤️ using Flutter.*
