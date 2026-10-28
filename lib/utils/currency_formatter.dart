class CurrencyFormatter {
  /// Format price range indicator (1 to 4 tier level)
  static String formatPriceRange(int? priceRange) {
    if (priceRange == null || priceRange < 1) return '';
    return '\$' * priceRange.clamp(1, 4);
  }

  /// Format currency amount nicely ($12.50)
  static String formatAmount(double? amount, {String? currency}) {
    if (amount == null) return '';
    final curr = currency ?? '\$';
    return '$curr${amount.toStringAsFixed(2)}';
  }
}
