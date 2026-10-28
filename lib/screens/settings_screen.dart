import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/restaurant_provider.dart';
import '../providers/settings_provider.dart';
import '../services/data_backup_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/haptic_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DataBackupService _backupService = DataBackupService();

  Future<void> _exportJson(SettingsProvider settings) async {
    AppHaptics.selectionClick(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressNotifier = ValueNotifier<String>('Packaging your memories & photos...');
    BuildContext? dialogContext;

    // Show loading modal while encoding photos and preparing JSON
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppDesignTokens.borderRadiusLarge,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: progressNotifier,
                builder: (context, statusText, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.champagneGold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Opening file save location...',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    ExportResult result;
    try {
      result = await _backupService.exportBackupToFile(
        settings: settings.settings,
        onProgress: (current, total, status) {
          progressNotifier.value = status;
        },
      );
    } catch (e) {
      result = ExportResult(success: false, errorMessage: e.toString());
    } finally {
      // Guaranteed: always dismiss dialog via captured dialogContext
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      } else if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!mounted) return;

    if (result.success) {
      AppHaptics.heavyImpact(context);
      _showExportSuccessDialog(result);
    } else if (result.canceled) {
      AppHaptics.lightImpact(context);
      _showExportCanceledDialog(result, settings);
    } else {
      AppHaptics.mediumImpact(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export backup: ${result.errorMessage ?? "Unknown error"}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showExportSuccessDialog(ExportResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sizeKb = (result.fileSizeBytes / 1024).toStringAsFixed(1);
    final sizeMb = (result.fileSizeBytes / (1024 * 1024)).toStringAsFixed(2);
    final sizeStr = result.fileSizeBytes > 1024 * 1024 ? '$sizeMb MB' : '$sizeKb KB';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Backup Saved!',
                style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your TableTales backup has been securely saved to your files with all restaurants, visit dates, and photos included.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                borderRadius: AppDesignTokens.borderRadiusMedium,
                border: Border.all(color: AppColors.champagneGold.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(Icons.restaurant_rounded, 'Restaurants', '${result.restaurantsCount}'),
                  const SizedBox(height: 8),
                  _buildSummaryRow(Icons.event_note_rounded, 'Visits & Dates', '${result.visitsCount}'),
                  const SizedBox(height: 8),
                  _buildSummaryRow(Icons.photo_library_rounded, 'Photos Included', '${result.photoFilesCount}'),
                  const SizedBox(height: 8),
                  _buildSummaryRow(Icons.data_usage_rounded, 'Total Size', sizeStr),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tip: You can also tap "Share Backup" to save an extra copy to Google Drive, WhatsApp, or email for ultimate security.',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
        actions: [
          if (result.tempPath != null || result.filePath != null)
            TextButton.icon(
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share Backup'),
              onPressed: () {
                AppHaptics.selectionClick(context);
                final path = result.tempPath ?? result.filePath!;
                _backupService.shareBackupFile(path);
              },
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.champagneGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusPill),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showExportCanceledDialog(ExportResult result, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
        title: const Text('File Save Canceled'),
        content: const Text(
          'You canceled choosing a save location. Your backup is prepared with all photos and dates. Would you like to try saving again, or share it directly to Google Drive or cloud?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss'),
          ),
          if (result.tempPath != null)
            TextButton.icon(
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share to Cloud'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _backupService.shareBackupFile(result.tempPath!);
              },
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.champagneGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusPill),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _exportJson(settings);
            },
            child: const Text('Try Saving Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.champagneGold),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showImportJsonDialog(
    RestaurantProvider provider,
    SettingsProvider settings,
  ) {
    AppHaptics.selectionClick(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.champagneGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restore_page_rounded, color: AppColors.champagneGold, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Restore JSON Backup',
                style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select your saved TableTales JSON backup file from My Files to bring back all your restaurant memories, dates, and photos.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open_rounded, size: 22),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Select Backup File (.json)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.champagneGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusMedium),
                elevation: 2,
              ),
              onPressed: () async {
                AppHaptics.selectionClick(context);
                Navigator.of(ctx).pop();
                await _pickAndProcessBackupFile(provider, settings);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.paste_rounded, size: 18),
              label: const Text('Paste JSON Text Manually'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusMedium),
              ),
              onPressed: () {
                AppHaptics.selectionClick(context);
                Navigator.of(ctx).pop();
                _showManualPasteDialog(provider, settings);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndProcessBackupFile(
    RestaurantProvider provider,
    SettingsProvider settings,
  ) async {
    try {
      final List<PlatformFile> pickedFiles = await FilePicker.pickFiles(
        dialogTitle: 'Select TableTales Backup File',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickedFiles.isEmpty) {
        return; // User canceled
      }

      final pickedFile = pickedFiles.first;
      String content;

      try {
        content = await pickedFile.xFile.readAsString();
      } catch (_) {
        if (pickedFile.path != null && pickedFile.path!.isNotEmpty) {
          final f = File(pickedFile.path!);
          content = await f.readAsString();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read the selected backup file.')),
          );
          return;
        }
      }

      if (!mounted) return;
      await _confirmAndRestoreBackup(provider, settings, content, pickedFile.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading backup file: $e')),
      );
    }
  }

  void _showManualPasteDialog(
    RestaurantProvider provider,
    SettingsProvider settings,
  ) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
        title: const Text('Paste JSON Backup', style: TextStyle(fontFamily: 'Serif')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste your TableTales JSON backup below:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 8,
              style: const TextStyle(fontSize: 12, fontFamily: 'Monospace'),
              decoration: const InputDecoration(
                hintText: '{"version": "2.0", "restaurants": [...], ...}',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.champagneGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusPill),
            ),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(ctx).pop();
                await _confirmAndRestoreBackup(provider, settings, text, 'Pasted JSON');
              }
            },
            child: const Text('Inspect & Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndRestoreBackup(
    RestaurantProvider provider,
    SettingsProvider settings,
    String jsonContent,
    String sourceName,
  ) async {
    final preview = await _backupService.inspectBackup(jsonContent);
    if (!mounted) return;

    if (!preview.isValid) {
      AppHaptics.mediumImpact(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invalid Backup File'),
          content: Text(preview.error ?? 'The chosen file is not a valid TableTales backup.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool cleanRestore = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          final dateStr = preview.exportedAt != null
              ? DateFormat.yMMMd().add_jm().format(preview.exportedAt!)
              : 'Unknown date';

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
            title: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.champagneGold),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Confirm Backup Restore',
                    style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Found TableTales backup ($sourceName):',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                      borderRadius: AppDesignTokens.borderRadiusMedium,
                      border: Border.all(color: AppColors.champagneGold.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(Icons.event_available_rounded, 'Backup Date', dateStr),
                        const SizedBox(height: 8),
                        _buildSummaryRow(Icons.restaurant_rounded, 'Restaurants', '${preview.restaurantsCount}'),
                        const SizedBox(height: 8),
                        _buildSummaryRow(Icons.event_note_rounded, 'Visits', '${preview.visitsCount}'),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          Icons.photo_library_rounded,
                          'Photos Included',
                          '${preview.photoFilesCount > 0 ? preview.photoFilesCount : preview.photosCount}',
                        ),
                        if (preview.coupleNames != null) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(Icons.people_outline_rounded, 'Couple', preview.coupleNames!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Restore Method:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: AppDesignTokens.borderRadiusMedium,
                    onTap: () => setModalState(() => cleanRestore = false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !cleanRestore ? AppColors.champagneGold.withValues(alpha: 0.12) : Colors.transparent,
                        border: Border.all(
                          color: !cleanRestore ? AppColors.champagneGold : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: !cleanRestore ? 1.5 : 1,
                        ),
                        borderRadius: AppDesignTokens.borderRadiusMedium,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !cleanRestore ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: !cleanRestore ? AppColors.champagneGold : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Merge with current data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text('Keep existing places, add new/updated items from backup.', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: AppDesignTokens.borderRadiusMedium,
                    onTap: () => setModalState(() => cleanRestore = true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cleanRestore ? AppColors.champagneGold.withValues(alpha: 0.12) : Colors.transparent,
                        border: Border.all(
                          color: cleanRestore ? AppColors.champagneGold : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: cleanRestore ? 1.5 : 1,
                        ),
                        borderRadius: AppDesignTokens.borderRadiusMedium,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cleanRestore ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: cleanRestore ? AppColors.champagneGold : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Clean restore (Recommended)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text('Clears current data & restores fresh from backup. Ideal for disaster recovery.', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.champagneGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusPill),
                ),
                onPressed: () async {
                  Navigator.of(dialogCtx).pop();
                  await _executeRestore(provider, settings, jsonContent, cleanRestore);
                },
                child: const Text('Restore Everything Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _executeRestore(
    RestaurantProvider provider,
    SettingsProvider settings,
    String jsonContent,
    bool cleanRestore,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressNotifier = ValueNotifier<String>('Starting restoration...');
    BuildContext? dialogContext;

    // Show restoring dialog with live progress updates
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppDesignTokens.borderRadiusLarge,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: progressNotifier,
                builder: (context, statusText, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.champagneGold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Please keep the app open',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    BackupReport? report;
    try {
      report = await _backupService.importFromJson(
        jsonContent,
        clearExisting: cleanRestore,
        onProgress: (current, total, status) {
          progressNotifier.value = status;
        },
      );
    } catch (e) {
      debugPrint('Error during import: $e');
    } finally {
      // 1. ALWAYS dismiss the loading dialog FIRST via its captured context before modifying providers!
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      } else if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!mounted) return;

    final finalReport = report;
    // 2. NOW refresh provider and settings AFTER the dialog is safely closed!
    if (finalReport != null && finalReport.isSuccess) {
      // Reload database records into provider
      await provider.loadData();

      // Update settings (which triggers theme/couple name updates)
      if (finalReport.restoredSettings != null) {
        await settings.updateSettings(finalReport.restoredSettings!);
      }

      if (!mounted) return;
      AppHaptics.heavyImpact(context);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Restore Complete!',
                  style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Successfully restored ${finalReport.restaurantsImported} restaurant(s), ${finalReport.visitsImported} visit date(s), and ${finalReport.photoFilesRestored} photo(s)!',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              if (finalReport.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Note: ${finalReport.warnings.first}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.champagneGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusPill),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Awesome'),
            ),
          ],
        ),
      );
    } else {
      AppHaptics.mediumImpact(context);
      final errorMsg = finalReport != null && finalReport.errors.isNotEmpty
          ? finalReport.errors.join('\n')
          : 'Could not restore backup data.';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Incomplete'),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showCoupleNamesDialog(BuildContext context, SettingsProvider settings) {
    AppHaptics.selectionClick(context);
    final controller = TextEditingController(text: settings.coupleNames);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
        title: const Text('Customize Couple Names'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Names (e.g. Alex & Sam)',
            hintText: 'Alex & Sam',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.champagneGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusPill),
            ),
            onPressed: () {
              AppHaptics.selectionClick(context);
              settings.setCoupleNames(controller.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);
    final provider = Provider.of<RestaurantProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences', style: TextStyle(fontFamily: 'Serif')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Brand Header
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: BrandLogo(size: 32, showTagline: true),
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Personalization
          const Text('Personalization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
          const SizedBox(height: 8),
          GlassContainer(
            borderRadius: AppDesignTokens.borderRadiusLarge,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.people_outline_rounded, color: AppColors.champagneGold),
                  title: const Text('Couple Names'),
                  subtitle: Text(settings.coupleNames.isNotEmpty ? settings.coupleNames : 'Not set'),
                  trailing: const Icon(Icons.edit_outlined, size: 18),
                  onTap: () => _showCoupleNamesDialog(context, settings),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: AppColors.champagneGold),
                  title: const Text('Appearance Theme'),
                  subtitle: Text(settings.themeMode.name.toUpperCase()),
                  trailing: DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light Mode')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark Mode')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        AppHaptics.selectionClick(context);
                        settings.setThemeMode(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Data & Backup
          const Text('Data Backup & Restore', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
          const SizedBox(height: 8),
          GlassContainer(
            borderRadius: AppDesignTokens.borderRadiusLarge,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined, color: AppColors.champagneGold),
                  title: const Text('Export JSON Backup'),
                  subtitle: const Text('Save all places, dates & photos to My Files'),
                  trailing: const Icon(Icons.download_rounded, color: AppColors.champagneGold, size: 20),
                  onTap: () => _exportJson(settings),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_page_outlined, color: AppColors.champagneGold),
                  title: const Text('Restore JSON Backup'),
                  subtitle: const Text('Pick backup file to restore places, dates & photos'),
                  trailing: const Icon(Icons.file_upload_rounded, color: AppColors.champagneGold, size: 20),
                  onTap: () => _showImportJsonDialog(provider, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Footer
          Center(
            child: Text(
              'TableTales v1.0.0\nPrivate Relationship Restaurant Memory Tracker',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
