import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final Color? textColor;

  const BrandLogo({
    super.key,
    this.size = 28,
    this.showTagline = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textCol = textColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom plate/table + pin icon mark
            Container(
              padding: EdgeInsets.all(size * 0.22),
              decoration: BoxDecoration(
                color: AppColors.champagneGold,
                borderRadius: BorderRadius.circular(size * 0.3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.champagneGold.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: size * 0.75,
                color: Colors.white,
              ),
            ),
            SizedBox(width: size * 0.4),
            Text(
              'TableTales',
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: textCol,
                fontFamily: 'Serif',
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Every place, a story. Every visit, a memory.',
            style: TextStyle(
              fontSize: size * 0.45,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
