import 'dart:math';
import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/currency_formatter.dart';
import '../utils/haptic_service.dart';
import 'glass_container.dart';

class RandomRestaurantDialog extends StatefulWidget {
  final List<Restaurant> restaurants;
  final Function(Restaurant) onSelected;

  const RandomRestaurantDialog({
    super.key,
    required this.restaurants,
    required this.onSelected,
  });

  @override
  State<RandomRestaurantDialog> createState() => _RandomRestaurantDialogState();
}

class _RandomRestaurantDialogState extends State<RandomRestaurantDialog> {
  Restaurant? _selected;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _pickRandom();
  }

  void _pickRandom() async {
    if (widget.restaurants.isEmpty) return;
    AppHaptics.selectionClick(context);
    setState(() {
      _isSpinning = true;
    });

    final random = Random();
    for (int i = 0; i < 8; i++) {
      await Future.delayed(Duration(milliseconds: 100 + i * 30));
      if (mounted) {
        setState(() {
          _selected = widget.restaurants[random.nextInt(widget.restaurants.length)];
        });
      }
    }

    if (mounted) {
      setState(() {
        _isSpinning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassContainer(
        borderRadius: AppDesignTokens.borderRadiusLarge,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.casino_rounded, color: AppColors.champagneGold, size: 24),
                SizedBox(width: 10),
                Text('Where to Eat Tonight?', style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            widget.restaurants.isEmpty
                ? const Text('Add restaurants to your collection first!')
                : Column(
                    children: [
                      const Text(
                        'Let TableTales pick a restaurant for your next memory:',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                          borderRadius: AppDesignTokens.borderRadiusLarge,
                          border: Border.all(color: AppColors.champagneGold, width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _selected?.name ?? '...',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Serif',
                              ),
                            ),
                            if (_selected?.cuisine != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${_selected!.cuisine} ${CurrencyFormatter.formatPriceRange(_selected?.priceRange)}',
                                style: const TextStyle(color: AppColors.warmOlive, fontWeight: FontWeight.w600),
                              ),
                            ],
                            if (_selected?.location != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _selected!.location!,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _isSpinning ? null : _pickRandom,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Spin Again'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.champagneGold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusPill),
                  ),
                  onPressed: _selected == null || _isSpinning
                      ? null
                      : () {
                          AppHaptics.heavyImpact(context);
                          Navigator.of(context).pop();
                          widget.onSelected(_selected!);
                        },
                  child: const Text('View Restaurant'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
