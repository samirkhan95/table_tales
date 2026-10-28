import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RatingBar extends StatelessWidget {
  final double rating;
  final double itemSize;
  final bool isInteractive;
  final ValueChanged<double>? onRatingChanged;

  const RatingBar({
    super.key,
    required this.rating,
    this.itemSize = 20,
    this.isInteractive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData iconData = Icons.star_border_rounded;
        Color iconColor = AppColors.lightTextMuted;

        if (rating >= starValue) {
          iconData = Icons.star_rounded;
          iconColor = AppColors.favoriteGold;
        } else if (rating >= starValue - 0.5) {
          iconData = Icons.star_half_rounded;
          iconColor = AppColors.favoriteGold;
        }

        final starWidget = Icon(
          iconData,
          size: itemSize,
          color: iconColor,
        );

        if (isInteractive) {
          return GestureDetector(
            onTap: () => onRatingChanged?.call(starValue.toDouble()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: starWidget,
            ),
          );
        }

        return starWidget;
      }),
    );
  }
}
