import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String coupleNames;
  final String collectionTitle;
  final String currencySymbol;
  final String defaultSort; // "recent", "visits", "name", "rating", "favorites"
  final bool enableHaptics;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.coupleNames = 'Alex & Sam',
    this.collectionTitle = 'TableTales',
    this.currencySymbol = '\$',
    this.defaultSort = 'recent',
    this.enableHaptics = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? coupleNames,
    String? collectionTitle,
    String? currencySymbol,
    String? defaultSort,
    bool? enableHaptics,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      coupleNames: coupleNames ?? this.coupleNames,
      collectionTitle: collectionTitle ?? this.collectionTitle,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      defaultSort: defaultSort ?? this.defaultSort,
      enableHaptics: enableHaptics ?? this.enableHaptics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'coupleNames': coupleNames,
      'collectionTitle': collectionTitle,
      'currencySymbol': currencySymbol,
      'defaultSort': defaultSort,
      'enableHaptics': enableHaptics,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      coupleNames: json['coupleNames'] as String? ?? 'Alex & Sam',
      collectionTitle: json['collectionTitle'] as String? ?? 'TableTales',
      currencySymbol: json['currencySymbol'] as String? ?? '\$',
      defaultSort: json['defaultSort'] as String? ?? 'recent',
      enableHaptics: json['enableHaptics'] as bool? ?? true,
    );
  }
}
