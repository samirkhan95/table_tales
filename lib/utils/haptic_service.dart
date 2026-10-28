import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class AppHaptics {
  static void lightImpact(dynamic context) {
    _perform(context, HapticFeedback.lightImpact);
  }

  static void mediumImpact(dynamic context) {
    _perform(context, HapticFeedback.mediumImpact);
  }

  static void heavyImpact(dynamic context) {
    _perform(context, HapticFeedback.heavyImpact);
  }

  static void selectionClick(dynamic context) {
    _perform(context, HapticFeedback.selectionClick);
  }

  static void _perform(dynamic context, Future<void> Function() hapticCall) {
    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (settings.enableHaptics) {
        hapticCall();
      }
    } catch (_) {
      // Fallback if provider is not available or haptics fail on device
      hapticCall();
    }
  }
}
