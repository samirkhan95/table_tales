import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  /// Whether to apply a BackdropFilter blur behind this container.
  final bool useBackdropBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = AppDesignTokens.glassBlur,
    this.borderRadius,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.onTap,
    this.useBackdropBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? AppDesignTokens.borderRadiusLarge;

    final defaultColor = color ??
        (isDark
            ? AppColors.darkSurface.withAlpha(
                useBackdropBlur ? (0.75 * 255).round() : (0.92 * 255).round())
            : AppColors.lightSurface.withAlpha(
                useBackdropBlur ? (0.82 * 255).round() : (0.95 * 255).round()));

    final defaultBorder = borderColor ??
        (isDark
            ? Colors.white.withAlpha((0.10 * 255).round())
            : Colors.black.withAlpha((0.06 * 255).round()));

    final effectiveShadow = boxShadow ??
        (isDark ? AppDesignTokens.glassShadowDark : AppDesignTokens.glassShadowLight);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: defaultColor,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: defaultBorder,
          width: borderWidth,
        ),
        boxShadow: effectiveShadow,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withAlpha((0.06 * 255).round()),
                  Colors.white.withAlpha((0.01 * 255).round()),
                ]
              : [
                  Colors.white.withAlpha((0.45 * 255).round()),
                  Colors.white.withAlpha((0.15 * 255).round()),
                ],
        ),
      ),
      child: child,
    );

    if (useBackdropBlur) {
      content = ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: effectiveRadius,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
