import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsProvider with ChangeNotifier {
  static const String _prefsKey = 'table_tales_settings';
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  String get coupleNames => _settings.coupleNames;
  String get collectionTitle => _settings.collectionTitle;
  String get currencySymbol => _settings.currencySymbol;
  String get defaultSort => _settings.defaultSort;
  bool get enableHaptics => _settings.enableHaptics;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_prefsKey);
      if (jsonStr != null) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
        _settings = AppSettings.fromJson(jsonMap);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_settings.toJson()));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await updateSettings(_settings.copyWith(themeMode: mode));
  }

  Future<void> setCoupleNames(String names) async {
    await updateSettings(_settings.copyWith(coupleNames: names));
  }

  Future<void> setCollectionTitle(String title) async {
    await updateSettings(_settings.copyWith(collectionTitle: title));
  }

  Future<void> setCurrencySymbol(String symbol) async {
    await updateSettings(_settings.copyWith(currencySymbol: symbol));
  }

  Future<void> setDefaultSort(String sort) async {
    await updateSettings(_settings.copyWith(defaultSort: sort));
  }
}
