import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDesignTokens {
  // Glass Blur Strength (adjust this value to change overall frosted glass blur intensity)
  static const double glassBlur = 16.0;

  // Border Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusPill = 999.0;

  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);
  static final BorderRadius borderRadiusPill = BorderRadius.circular(radiusPill);

  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 24.0;

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 220);
  static const Duration animSlow = Duration(milliseconds: 300);

  // Easing Curves
  static const Curve curveStandard = Curves.fastOutSlowIn;
  static const Curve curveSpring = Curves.easeOutCubic;

  // Glass Material Colors
  static Color glassBgLight = AppColors.lightBg.withAlpha((0.75 * 255).round());
  static Color glassBgDark = AppColors.darkSurface.withAlpha((0.75 * 255).round());

  static Color glassBorderLight = Colors.white.withAlpha((0.6 * 255).round());
  static Color glassBorderDark = Colors.white.withAlpha((0.12 * 255).round());

  // Shadows
  static List<BoxShadow> glassShadowLight = [
    BoxShadow(
      color: Colors.black.withAlpha((0.06 * 255).round()),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.champagneGold.withAlpha((0.08 * 255).round()),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glassShadowDark = [
    BoxShadow(
      color: Colors.black.withAlpha((0.35 * 255).round()),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}
